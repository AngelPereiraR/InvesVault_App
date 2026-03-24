import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/batch/batch_cubit.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// Lightweight data holder so callers don't need to import BatchModel.
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

/// Pass [batch] to open in edit mode; leave null for create mode.
/// [maxQuantity] caps the allowed quantity (remaining unassigned stock).
class AddEditBatchDialog extends StatefulWidget {
  final int warehouseProductId;
  final BatchItem? batch;
  final double maxQuantity;

  const AddEditBatchDialog({
    super.key,
    required this.warehouseProductId,
    required this.maxQuantity,
    this.batch,
  });

  @override
  State<AddEditBatchDialog> createState() => _AddEditBatchDialogState();
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
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
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
      title: Text(_isEdit ? 'Editar caducidad' : 'Asignar caducidad'),
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
                  final max = widget.maxQuantity;
                  if (n > max) {
                    final maxStr = max % 1 == 0
                        ? max.toInt().toString()
                        : max.toString();
                    return 'Máximo disponible: $maxStr';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              label: 'Guardar',
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
