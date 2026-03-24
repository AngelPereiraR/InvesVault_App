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
      // Build payload — only include fields the caller explicitly provided.
      // The dialog always passes current values, so null = user cleared it.
      final payload = <String, dynamic>{};
      if (quantity != null) payload['quantity'] = quantity;
      if (expiryDate != null) payload['expiry_date'] = expiryDate;
      if (notes != null) payload['notes'] = notes;
      await _repository.updateBatch(batchId, payload);
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

  /// Trims batch quantities so the total never exceeds [maxStock].
  /// Batches without expiry date are removed first, then by newest creation.
  /// Called automatically when the product's stock is reduced.
  Future<void> trimToStock(int warehouseProductId, double maxStock) async {
    if (maxStock < 0) maxStock = 0;

    // Use already-loaded batches or fetch from API.
    List<BatchModel> batches;
    final currentState = state;
    if (currentState is BatchLoaded) {
      batches = currentState.batches;
    } else {
      try {
        batches = await _repository.getBatches(warehouseProductId);
      } catch (_) {
        return; // Can't trim without data — skip silently.
      }
    }

    final totalBatched =
        batches.fold<double>(0.0, (sum, b) => sum + b.quantity);
    if (totalBatched <= maxStock) return; // Nothing to trim.

    // Sort: no-expiry first (less informative → remove first),
    // then by createdAt descending (newest first).
    final sorted = [...batches]
      ..sort((a, b) {
        if (a.expiryDate == null && b.expiryDate != null) return -1;
        if (a.expiryDate != null && b.expiryDate == null) return 1;
        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      });

    double toRemove = totalBatched - maxStock;
    for (final b in sorted) {
      if (toRemove <= 0) break;
      if (b.quantity <= toRemove) {
        await _repository.deleteBatch(b.id);
        toRemove -= b.quantity;
      } else {
        await _repository.updateBatch(
            b.id, {'quantity': b.quantity - toRemove});
        toRemove = 0;
      }
    }

    // Refresh state only if the tile was already expanded.
    if (currentState is BatchLoaded) {
      await load(warehouseProductId);
    }
  }
}
