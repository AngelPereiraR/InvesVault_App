# Expiry Dates & Batches — Frontend (Flutter) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add batch management (list, create, edit, delete) to the product-in-warehouse detail view, show expiry-warning badges in the warehouse product list, fire local push notifications for expiry warnings from the backend, and differentiate expiry-type notifications with a 📅 icon in the notifications screen.

**Architecture:** New data layer (`BatchModel`, `BatchRemoteDatasource`, `BatchRepository`) + new `BatchCubit` feed the product detail screen. `NotificationModel` gains `type`/`batchId` fields. `NotificationService` gets a new `showExpiryNotification` method. `NotificationCubit.load` fires local pushes for unseen `expiry_warning` notifications using `SharedPreferences` to deduplicate. `WarehouseProductModel` gains `hasExpiringBatch` virtual field from the API.

**Tech Stack:** Flutter/Dart, flutter_bloc, Dio, flutter_local_notifications, shared_preferences, Equatable.

**Working directory:** `E:/Proyectos/InvesVault_App`

**Prerequisite:** Backend plan (`2026-03-24-expiry-batches-backend.md`) must be deployed or running locally before testing API calls.

---

## File Map

### New files
| Path | Responsibility |
|---|---|
| `lib/data/models/batch_model.dart` | `BatchModel` — fromJson/toJson/copyWith/Equatable |
| `lib/data/datasources/batch_remote_datasource.dart` | Dio calls: list, create, update, delete |
| `lib/data/repositories/batch_repository.dart` | Thin wrapper around datasource |
| `lib/presentation/cubits/batch/batch_cubit.dart` | Cubit: load, add, edit, delete |
| `lib/presentation/cubits/batch/batch_state.dart` | States: Initial/Loading/Loaded/Error |
| `lib/presentation/dialogs/add_edit_batch_dialog.dart` | AlertDialog for create/edit with date picker |

### Modified files
| Path | Change |
|---|---|
| `lib/core/constants/api_constants.dart` | Add batch endpoint constants |
| `lib/data/models/notification_model.dart` | Add `type` and `batchId` fields |
| `lib/data/models/warehouse_product_model.dart` | Add `hasExpiringBatch` field |
| `lib/core/services/notification_service.dart` | Add `showExpiryNotification()` + `expiry_channel` |
| `lib/presentation/cubits/notification/notification_cubit.dart` | Fire local push for new expiry warnings |
| `lib/app.dart` | Wire `BatchRemoteDatasource`, `BatchRepository`, `BatchCubit` |
| `lib/presentation/screens/warehouses/warehouse_detail_screen.dart` | Show batch list when expanding a product tile (spec: "Al expandir un producto en el almacén") |
| Notification screen | Show 📅 icon for `expiry_warning` type notifications |
| Warehouse products list tile | Show orange warning badge when `hasExpiringBatch == true` |

---

## Task 1: API constants for batches

**Files:**
- Modify: `lib/core/constants/api_constants.dart`

- [ ] **Step 1: Add batch endpoints**

Add after the Warehouse Products section:
```dart
  // Batches
  static String batchesByWarehouseProduct(int warehouseProductId) =>
      '/warehouse-products/$warehouseProductId/batches';
  static String batchById(int id) => '/warehouse-product-batches/$id';
```

- [ ] **Step 2: Verify no syntax errors**
```bash
flutter analyze lib/core/constants/api_constants.dart
```
Expected: No issues.

- [ ] **Step 3: Commit**
```bash
git add lib/core/constants/api_constants.dart
git commit -m "feat: add batch API endpoint constants"
```

---

## Task 2: `BatchModel`

**Files:**
- Create: `lib/data/models/batch_model.dart`

- [ ] **Step 1: Create the model**

```dart
// lib/data/models/batch_model.dart
import 'package:equatable/equatable.dart';

class BatchModel extends Equatable {
  final int id;
  final int warehouseProductId;
  final double quantity;
  final String? expiryDate; // ISO date string "YYYY-MM-DD" or null
  final String? notes;
  final String? createdAt;

  const BatchModel({
    required this.id,
    required this.warehouseProductId,
    required this.quantity,
    this.expiryDate,
    this.notes,
    this.createdAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as int,
      warehouseProductId: json['warehouse_product_id'] as int,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      expiryDate: json['expiry_date'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'warehouse_product_id': warehouseProductId,
        'quantity': quantity,
        if (expiryDate != null) 'expiry_date': expiryDate,
        if (notes != null) 'notes': notes,
      };

  BatchModel copyWith({
    int? id,
    int? warehouseProductId,
    double? quantity,
    String? expiryDate,
    String? notes,
    String? createdAt,
  }) =>
      BatchModel(
        id: id ?? this.id,
        warehouseProductId: warehouseProductId ?? this.warehouseProductId,
        quantity: quantity ?? this.quantity,
        expiryDate: expiryDate ?? this.expiryDate,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns true if this batch has an expiry date within the next 7 days.
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final expiry = DateTime.tryParse(expiryDate!);
    if (expiry == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = expiry.difference(today).inDays;
    return diff >= 0 && diff <= 7;
  }

  @override
  List<Object?> get props => [id, warehouseProductId, quantity, expiryDate, notes];
}
```

- [ ] **Step 2: Analyze**
```bash
flutter analyze lib/data/models/batch_model.dart
```
Expected: No issues.

- [ ] **Step 3: Commit**
```bash
git add lib/data/models/batch_model.dart
git commit -m "feat: add BatchModel"
```

---

## Task 3: `BatchRemoteDatasource` + `BatchRepository`

**Files:**
- Create: `lib/data/datasources/batch_remote_datasource.dart`
- Create: `lib/data/repositories/batch_repository.dart`

- [ ] **Step 1: Datasource**

```dart
// lib/data/datasources/batch_remote_datasource.dart
import 'package:dio/dio.dart';
import '../models/batch_model.dart';
import '../../core/constants/api_constants.dart';

class BatchRemoteDatasource {
  final Dio _dio;
  BatchRemoteDatasource(this._dio);

  Future<List<BatchModel>> getBatches(int warehouseProductId) async {
    try {
      final response = await _dio.get(
        ApiConstants.batchesByWarehouseProduct(warehouseProductId),
      );
      return (response.data as List)
          .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<BatchModel> createBatch(
      int warehouseProductId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiConstants.batchesByWarehouseProduct(warehouseProductId),
      data: data,
    );
    return BatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BatchModel> updateBatch(int id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.batchById(id), data: data);
    return BatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBatch(int id) =>
      _dio.delete(ApiConstants.batchById(id));
}
```

- [ ] **Step 2: Repository**

```dart
// lib/data/repositories/batch_repository.dart
import '../datasources/batch_remote_datasource.dart';
import '../models/batch_model.dart';

class BatchRepository {
  final BatchRemoteDatasource _datasource;
  BatchRepository(this._datasource);

  Future<List<BatchModel>> getBatches(int warehouseProductId) =>
      _datasource.getBatches(warehouseProductId);

  Future<BatchModel> createBatch(
          int warehouseProductId, Map<String, dynamic> data) =>
      _datasource.createBatch(warehouseProductId, data);

  Future<BatchModel> updateBatch(int id, Map<String, dynamic> data) =>
      _datasource.updateBatch(id, data);

  Future<void> deleteBatch(int id) => _datasource.deleteBatch(id);
}
```

- [ ] **Step 3: Analyze**
```bash
flutter analyze lib/data/datasources/batch_remote_datasource.dart lib/data/repositories/batch_repository.dart
```

- [ ] **Step 4: Commit**
```bash
git add lib/data/datasources/batch_remote_datasource.dart lib/data/repositories/batch_repository.dart
git commit -m "feat: add BatchRemoteDatasource and BatchRepository"
```

---

## Task 4: `BatchCubit` + `BatchState`

**Files:**
- Create: `lib/presentation/cubits/batch/batch_state.dart`
- Create: `lib/presentation/cubits/batch/batch_cubit.dart`

- [ ] **Step 1: State file**

```dart
// lib/presentation/cubits/batch/batch_state.dart
part of 'batch_cubit.dart';

abstract class BatchState extends Equatable {
  const BatchState();
  @override
  List<Object?> get props => [];
}

class BatchInitial extends BatchState {
  const BatchInitial();
}

class BatchLoading extends BatchState {
  const BatchLoading();
}

class BatchLoaded extends BatchState {
  final List<BatchModel> batches;
  final int warehouseProductId;
  const BatchLoaded({required this.batches, required this.warehouseProductId});
  @override
  List<Object?> get props => [batches, warehouseProductId];
}

class BatchError extends BatchState {
  final String message;
  const BatchError(this.message);
  @override
  List<Object?> get props => [message];
}

class BatchMutating extends BatchState {
  // emitted while create/update/delete is in progress
  final List<BatchModel> batches;
  const BatchMutating({required this.batches});
  @override
  List<Object?> get props => [batches];
}
```

- [ ] **Step 2: Cubit file**

```dart
// lib/presentation/cubits/batch/batch_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_messages.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/repositories/batch_repository.dart';

part 'batch_state.dart';

class BatchCubit extends Cubit<BatchState> {
  final BatchRepository _repository;

  BatchCubit(this._repository) : super(const BatchInitial());

  Future<void> load(int warehouseProductId) async {
    emit(const BatchLoading());
    try {
      final batches = await _repository.getBatches(warehouseProductId);
      emit(BatchLoaded(batches: batches, warehouseProductId: warehouseProductId));
    } catch (e) {
      emit(BatchError(friendlyError(e)));
    }
  }

  Future<void> addBatch({
    required int warehouseProductId,
    required double quantity,
    String? expiryDate,
    String? notes,
  }) async {
    final current = state;
    final currentBatches =
        current is BatchLoaded ? current.batches : <BatchModel>[];
    emit(BatchMutating(batches: currentBatches));
    try {
      await _repository.createBatch(warehouseProductId, {
        'quantity': quantity,
        if (expiryDate != null) 'expiry_date': expiryDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      await load(warehouseProductId);
    } catch (e) {
      emit(BatchError(friendlyError(e)));
    }
  }

  Future<void> editBatch({
    required int batchId,
    required int warehouseProductId,
    double? quantity,
    String? expiryDate,
    String? notes,
  }) async {
    final current = state;
    final currentBatches =
        current is BatchLoaded ? current.batches : <BatchModel>[];
    emit(BatchMutating(batches: currentBatches));
    try {
      await _repository.updateBatch(batchId, {
        if (quantity != null) 'quantity': quantity,
        // Only include these fields if the caller explicitly passed a value.
        // The dialog always passes the current value, so null here means
        // "user cleared it intentionally" and is safe to send.
        if (expiryDate != null || notes != null) ...{
          if (expiryDate != null) 'expiry_date': expiryDate,
          if (notes != null) 'notes': notes,
        },
      });
      await load(warehouseProductId);
    } catch (e) {
      emit(BatchError(friendlyError(e)));
    }
  }

  Future<void> deleteBatch({
    required int batchId,
    required int warehouseProductId,
  }) async {
    final current = state;
    final currentBatches =
        current is BatchLoaded ? current.batches : <BatchModel>[];
    emit(BatchMutating(batches: currentBatches));
    try {
      await _repository.deleteBatch(batchId);
      await load(warehouseProductId);
    } catch (e) {
      emit(BatchError(friendlyError(e)));
    }
  }
}
```

- [ ] **Step 3: Analyze**
```bash
flutter analyze lib/presentation/cubits/batch/
```

- [ ] **Step 4: Commit**
```bash
git add lib/presentation/cubits/batch/
git commit -m "feat: add BatchCubit and BatchState"
```

---

## Task 5: Wire DI in `app.dart`

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Add imports**

Add to the import block:
```dart
import 'data/datasources/batch_remote_datasource.dart';
import 'data/repositories/batch_repository.dart';
import 'presentation/cubits/batch/batch_cubit.dart';
```

- [ ] **Step 2: Declare datasource + repo fields**

In `_InvesVaultAppState`, after `_dashboardDs`:
```dart
late final BatchRemoteDatasource _batchDs;
late final BatchRepository _batchRepo;
```

- [ ] **Step 3: Initialize in `initState`**

After `_dashboardRepo = DashboardRepository(_dashboardDs);`:
```dart
_batchDs = BatchRemoteDatasource(dio);
_batchRepo = BatchRepository(_batchDs);
```

- [ ] **Step 4: Add BlocProvider**

In the `MultiBlocProvider` list, after `ProductWarehousesCubit`:
```dart
BlocProvider(
  create: (_) => BatchCubit(_batchRepo),
),
```

- [ ] **Step 5: Analyze and verify app compiles**
```bash
flutter analyze lib/app.dart
```

- [ ] **Step 6: Commit**
```bash
git add lib/app.dart
git commit -m "feat: wire BatchDatasource, BatchRepository, BatchCubit in app.dart"
```

---

## Task 6: `AddEditBatchDialog`

**Files:**
- Create: `lib/presentation/dialogs/add_edit_batch_dialog.dart`

- [ ] **Step 1: Create dialog**

```dart
// lib/presentation/dialogs/add_edit_batch_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/batch/batch_cubit.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// Pass [batch] to open in edit mode; leave null for create mode.
class AddEditBatchDialog extends StatefulWidget {
  final int warehouseProductId;
  final BatchItem? batch; // null = create mode

  const AddEditBatchDialog({
    super.key,
    required this.warehouseProductId,
    this.batch,
  });

  @override
  State<AddEditBatchDialog> createState() => _AddEditBatchDialogState();
}

// Lightweight data holder to avoid importing the full model in the call site.
class BatchItem {
  final int id;
  final double quantity;
  final String? expiryDate;
  final String? notes;
  const BatchItem({
    required this.id,
    required this.quantity,
    this.expiryDate,
    this.notes,
  });
}

class _AddEditBatchDialogState extends State<AddEditBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _selectedDate;
  bool _loading = false;

  bool get _isEdit => widget.batch != null;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(
        text: _isEdit ? widget.batch!.quantity.toString() : '');
    _notesCtrl =
        TextEditingController(text: _isEdit ? (widget.batch!.notes ?? '') : '');
    if (_isEdit && widget.batch!.expiryDate != null) {
      _selectedDate = DateTime.tryParse(widget.batch!.expiryDate!);
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _expiryIso() {
    if (_selectedDate == null) return null;
    final y = _selectedDate!.year.toString().padLeft(4, '0');
    final m = _selectedDate!.month.toString().padLeft(2, '0');
    final d = _selectedDate!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final qty = double.parse(_quantityCtrl.text.trim());
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await context.read<BatchCubit>().editBatch(
              batchId: widget.batch!.id,
              warehouseProductId: widget.warehouseProductId,
              quantity: qty,
              expiryDate: _expiryIso(),
              notes: notes,
            );
      } else {
        await context.read<BatchCubit>().addBatch(
              warehouseProductId: widget.warehouseProductId,
              quantity: qty,
              expiryDate: _expiryIso(),
              notes: notes,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar lote' : 'Añadir lote'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _quantityCtrl,
                label: 'Cantidad',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Número inválido';
                  if (n <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Date picker row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Sin fecha de caducidad'
                          : 'Vence: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Seleccionar'),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      onPressed: () => setState(() => _selectedDate = null),
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Quitar fecha',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _notesCtrl,
                label: 'Notas (opcional)',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: _isEdit ? 'Guardar' : 'Añadir',
              fullWidth: false,
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze**
```bash
flutter analyze lib/presentation/dialogs/add_edit_batch_dialog.dart
```

- [ ] **Step 3: Commit**
```bash
git add lib/presentation/dialogs/add_edit_batch_dialog.dart
git commit -m "feat: add AddEditBatchDialog with date picker"
```

---

## Task 7: Show batches when expanding a product in warehouse detail

**Files:**
- Modify: `lib/presentation/screens/warehouses/warehouse_detail_screen.dart`

> The spec says batches appear "al expandir un producto en el almacén" — i.e. inside the warehouse product list, not the product→warehouses screen. The warehouse detail screen is the correct target. Read the file first to understand how product tiles are rendered, then add the expandable batch section.

- [ ] **Step 1: Read and understand `warehouse_detail_screen.dart`**

Open the file. Identify the widget that renders each `WarehouseProduct` item (look for a `_ProductTile` or similar class). Determine whether the screen already uses `ExpansionTile` or `AnimatedContainer`; if not, we'll wrap the product tile in an `ExpansionTile`.

- [ ] **Step 2: Add batch imports**

Add imports at top of the file:
```dart
import '../../cubits/batch/batch_cubit.dart';
import '../../dialogs/add_edit_batch_dialog.dart';
import '../../../data/models/batch_model.dart';
```

- [ ] **Step 3: Wrap the product tile in an `ExpansionTile` and load batches on expand**

In the product tile widget, replace the root `Card`/`ListTile` with an `ExpansionTile`. Pass the current title/subtitle/leading into the `ExpansionTile`'s `title`/`subtitle`/`leading` props. In `onExpansionChanged`, call `context.read<BatchCubit>().load(wp.id)` when `expanded == true`. Add a `BlocBuilder<BatchCubit, BatchState>` as the expansion child:

```dart
BlocBuilder<BatchCubit, BatchState>(
  builder: (context, state) {
    final batches = state is BatchLoaded
        ? state.batches
        : state is BatchMutating
            ? state.batches
            : <BatchModel>[];
    final isLoading = state is BatchLoading || state is BatchMutating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Lotes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (state is BatchError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(state.message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ...batches.map((b) => _BatchTile(
              batch: b,
              warehouseProductId: wp.id, // wp is the WarehouseProductModel in scope
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<BatchCubit>(),
                child: AddEditBatchDialog(
                  warehouseProductId: wp.id,
                ),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir lote'),
          ),
        ),
      ],
    );
  },
),
```

- [ ] **Step 4: Add `_BatchTile` private widget**

```dart
class _BatchTile extends StatelessWidget {
  final BatchModel batch;
  final int warehouseProductId;
  const _BatchTile({required this.batch, required this.warehouseProductId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isExpiring = batch.isExpiringSoon;
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.inventory_2_outlined,
        size: 18,
        color: isExpiring ? Colors.orange : cs.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Text('${batch.quantity % 1 == 0 ? batch.quantity.toInt() : batch.quantity} uds'),
          if (batch.expiryDate != null) ...[
            const SizedBox(width: 8),
            Text(
              'vence ${batch.expiryDate}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: isExpiring ? Colors.orange : null),
            ),
            if (isExpiring) ...[
              const SizedBox(width: 4),
              const Text('⚠️', style: TextStyle(fontSize: 12)),
            ],
          ] else
            Text(
              ' sin fecha',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
      subtitle:
          batch.notes != null ? Text(batch.notes!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Editar',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<BatchCubit>(),
                child: AddEditBatchDialog(
                  warehouseProductId: warehouseProductId,
                  batch: BatchItem(
                    id: batch.id,
                    quantity: batch.quantity,
                    expiryDate: batch.expiryDate,
                    notes: batch.notes,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
            tooltip: 'Eliminar',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Eliminar lote'),
                  content: const Text('¿Estás seguro de que quieres eliminar este lote?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<BatchCubit>().deleteBatch(
                      batchId: batch.id,
                      warehouseProductId: warehouseProductId,
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Analyze**
```bash
flutter analyze lib/presentation/screens/products/
```

- [ ] **Step 6: Commit**
```bash
git add lib/presentation/screens/products/
git commit -m "feat: show batch list with add/edit/delete in product detail screen"
```

---

## Task 8: `hasExpiringBatch` in `WarehouseProductModel` + warning badge

**Files:**
- Modify: `lib/data/models/warehouse_product_model.dart`
- Modify: the warehouse product list tile (find in warehouse_detail_screen or a widget)

- [ ] **Step 1: Add field to `WarehouseProductModel`**

Read the file, then add:
```dart
final bool hasExpiringBatch;
```
In constructor (with default `false`):
```dart
this.hasExpiringBatch = false,
```
In `fromJson`:
```dart
hasExpiringBatch: json['has_expiring_batch'] as bool? ?? false,
```
In `copyWith`:
```dart
bool? hasExpiringBatch,
// ...
hasExpiringBatch: hasExpiringBatch ?? this.hasExpiringBatch,
```
In `props`:
```dart
..., hasExpiringBatch
```

- [ ] **Step 2: Add orange warning badge in the warehouse product list tile**

Find where `isLowStock` badge is rendered (likely in `warehouse_detail_screen.dart` or a `_ProductTile` widget). After the low-stock badge, add:

```dart
if (wp.hasExpiringBatch) ...[
  const SizedBox(width: 8),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      '📅 Caduca pronto',
      style: TextStyle(
        fontSize: 10,
        color: Colors.orange,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
],
```

- [ ] **Step 3: Analyze**
```bash
flutter analyze lib/data/models/warehouse_product_model.dart
```

- [ ] **Step 4: Commit**
```bash
git add lib/data/models/warehouse_product_model.dart
git commit -m "feat: add hasExpiringBatch field and orange badge in warehouse product list"
```

---

## Task 9: `NotificationModel` — add `type` and `batchId`

**Files:**
- Modify: `lib/data/models/notification_model.dart`

- [ ] **Step 1: Add fields**

Add:
```dart
final String type;       // 'low_stock' | 'expiry_warning'
final int? batchId;
```

Constructor:
```dart
this.type = 'low_stock',
this.batchId,
```

`fromJson`:
```dart
type: json['type'] as String? ?? 'low_stock',
batchId: json['batch_id'] as int?,
```

`copyWith`:
```dart
String? type,
int? batchId,
// ...
type: type ?? this.type,
batchId: batchId ?? this.batchId,
```

`props`: add `type`, `batchId`.

- [ ] **Step 2: Add convenience getter**

```dart
bool get isExpiryWarning => type == 'expiry_warning';
```

- [ ] **Step 3: Analyze**
```bash
flutter analyze lib/data/models/notification_model.dart
```

- [ ] **Step 4: Commit**
```bash
git add lib/data/models/notification_model.dart
git commit -m "feat: add type and batchId fields to NotificationModel"
```

---

## Task 10: `NotificationService` — expiry channel

**Files:**
- Modify: `lib/core/services/notification_service.dart`

- [ ] **Step 1: Add `showExpiryNotification` method**

After `showLowStockNotification`, add:
```dart
Future<void> showExpiryNotification({
  required int id,
  required String productName,
  required String expiryDate,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'expiry_channel',
    'Caducidad',
    channelDescription: 'Alertas de productos próximos a caducar',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _plugin.show(
    id,
    '📅 Caduca pronto: $productName',
    'Vence el $expiryDate',
    details,
  );
}
```

- [ ] **Step 2: Analyze**
```bash
flutter analyze lib/core/services/notification_service.dart
```

- [ ] **Step 3: Commit**
```bash
git add lib/core/services/notification_service.dart
git commit -m "feat: add showExpiryNotification with expiry_channel"
```

---

## Task 11: `NotificationCubit` — fire local push for new expiry warnings

**Files:**
- Modify: `lib/presentation/cubits/notification/notification_cubit.dart`

- [ ] **Step 1: Add `NotificationService` and `SharedPreferences` dependency**

Add to the cubit constructor:
```dart
final NotificationService _notificationService;
// SharedPreferences key
static const _seenKey = 'seen_expiry_notification_ids';
```

Update constructor signature:
```dart
NotificationCubit(this._repository, this._notificationService) : super(const NotificationInitial());
```

Add imports:
```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
```

- [ ] **Step 2: Fire push in `load`**

At the end of the `load` method, after emitting `NotificationLoaded`, add:
```dart
await _fireExpiryPushes(notifications);
```

Add private method:
```dart
Future<void> _fireExpiryPushes(List<NotificationModel> notifications) async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getStringList(_seenKey)?.toSet() ?? {};

  for (final n in notifications) {
    if (!n.isExpiryWarning) continue;
    final key = n.id.toString();
    if (seen.contains(key)) continue;

    await _notificationService.showExpiryNotification(
      id: n.id,
      productName: n.productName ?? 'Producto',
      expiryDate: n.message, // message contains the date info from backend
    );
    seen.add(key);
  }

  await prefs.setStringList(_seenKey, seen.toList());
}
```

- [ ] **Step 3: Update `app.dart` to pass `notificationService` to `NotificationCubit`**

In `app.dart`, find:
```dart
BlocProvider(
  create: (_) => NotificationCubit(_notificationRepo),
),
```
Change to:
```dart
BlocProvider(
  create: (_) => NotificationCubit(_notificationRepo, widget.notificationService),
),
```

- [ ] **Step 4: Analyze**
```bash
flutter analyze lib/presentation/cubits/notification/notification_cubit.dart lib/app.dart
```

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/cubits/notification/notification_cubit.dart lib/app.dart
git commit -m "feat: fire local push for unseen expiry_warning notifications"
```

---

## Task 12: Notifications screen — 📅 icon for expiry_warning

**Files:**
- Modify: the notifications screen (find it under `lib/presentation/screens/`)

> **Find the file:** `grep -r "NotificationCubit\|notificationList" lib/presentation/screens/` — likely `lib/presentation/screens/notifications/notifications_screen.dart`.

- [ ] **Step 1: Add type-based icon**

Find where the notification list tile is built. Change the leading icon to:
```dart
leading: CircleAvatar(
  backgroundColor: n.isExpiryWarning
      ? Colors.orange.withValues(alpha: 0.15)
      : cs.primaryContainer,
  child: Text(
    n.isExpiryWarning ? '📅' : '📦',
    style: const TextStyle(fontSize: 16),
  ),
),
```

- [ ] **Step 2: Analyze**
```bash
flutter analyze lib/presentation/screens/
```

- [ ] **Step 3: Commit**
```bash
git add lib/presentation/screens/
git commit -m "feat: show calendar icon for expiry_warning notifications"
```

---

## Task 13: Smoke test & build verification

- [ ] **Step 1: Full analyze**
```bash
flutter analyze
```
Expected: 0 errors, warnings acceptable.

- [ ] **Step 2: Run tests**
```bash
flutter test
```
Expected: all pass.

- [ ] **Step 3: Build APK to confirm no compile errors**
```bash
flutter build apk --debug
```
Expected: Build successful.

- [ ] **Step 4: Final commit if any leftover fixes**
```bash
git add -p
git commit -m "fix: address any analyzer warnings from batch feature"
```

---

## Done

Backend plan: `docs/superpowers/plans/2026-03-24-expiry-batches-backend.md`
Frontend plan: this file.

Implement backend first, then frontend (or in parallel in separate worktrees).
