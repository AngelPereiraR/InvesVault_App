import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/stock_change_model.dart';
import '../../../data/repositories/stock_change_repository.dart';

part 'stock_change_state.dart';

class StockChangeCubit extends Cubit<StockChangeState> {
  final StockChangeRepository _repository;

  StockChangeCubit(this._repository) : super(const StockChangeInitial());

  Future<void> loadByProduct(int productId, [FilterParams params = FilterParams.empty]) async {
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByProduct(productId, params);
      emit(StockChangeLoaded(changes));
    } catch (e) {
      emit(StockChangeError(friendlyError(e)));
    }
  }

  Future<void> loadByWarehouse(int warehouseId, [FilterParams params = FilterParams.empty]) async {
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByWarehouse(warehouseId, params);
      emit(StockChangeLoaded(changes));
    } catch (e) {
      emit(StockChangeError(friendlyError(e)));
    }
  }

  Future<void> loadByUser(int userId, [FilterParams params = FilterParams.empty]) async {
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByUser(userId, params);
      emit(StockChangeLoaded(changes));
    } catch (e) {
      emit(StockChangeError(friendlyError(e)));
    }
  }

  /// Silently creates a stock change without modifying current UI state.
  Future<void> create({
    required int warehouseId,
    required int productId,
    required int changeQuantity,
    String changeType = 'inbound',
    String? reason,
  }) async {
    try {
      await _repository.create({
        'warehouse_id': warehouseId,
        'product_id': productId,
        'change_quantity': changeQuantity,
        'change_type': changeType,
        if (reason != null) 'reason': reason,
      });
    } catch (_) {
      // Silent — stock change errors shouldn't block the shopping list flow
    }
  }
}
