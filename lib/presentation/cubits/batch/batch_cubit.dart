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
}
