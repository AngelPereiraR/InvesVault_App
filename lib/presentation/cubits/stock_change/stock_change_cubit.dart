import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../data/models/stock_change_model.dart';
import '../../../data/repositories/stock_change_repository.dart';

part 'stock_change_state.dart';

class StockChangeCubit extends Cubit<StockChangeState> {
  final StockChangeRepository _repository;
  String _loadMode = 'warehouse'; // 'product' | 'warehouse' | 'user'
  int _loadEntityId = 0;
  FilterParams _currentParams = FilterParams.empty;

  StockChangeCubit(this._repository) : super(const StockChangeInitial());

  Future<void> loadByProduct(int productId, [FilterParams params = FilterParams.empty]) async {
    _loadMode = 'product';
    _loadEntityId = productId;
    _currentParams = params;
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByProduct(productId, params);
      final limit = params.limit ?? 20;
      emit(StockChangeLoaded(changes, hasMore: changes.length >= limit, currentPage: 1));
    } catch (e) {
      emit(StockChangeError(friendlyError(e)));
    }
  }

  Future<void> loadByWarehouse(int warehouseId, [FilterParams params = FilterParams.empty]) async {
    _loadMode = 'warehouse';
    _loadEntityId = warehouseId;
    _currentParams = params;
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByWarehouse(warehouseId, params);
      final limit = params.limit ?? 20;
      emit(StockChangeLoaded(changes, hasMore: changes.length >= limit, currentPage: 1));
    } catch (e) {
      emit(StockChangeError(friendlyError(e)));
    }
  }

  Future<void> loadByUser(int userId, [FilterParams params = FilterParams.empty]) async {
    _loadMode = 'user';
    _loadEntityId = userId;
    _currentParams = params;
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByUser(userId, params);
      final limit = params.limit ?? 20;
      emit(StockChangeLoaded(changes, hasMore: changes.length >= limit, currentPage: 1));
    } catch (e) {
      emit(StockChangeError(friendlyError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! StockChangeLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final params = _currentParams.copyWith(page: nextPage);
      final List<StockChangeModel> newItems;
      if (_loadMode == 'product') {
        newItems = await _repository.getByProduct(_loadEntityId, params);
      } else if (_loadMode == 'user') {
        newItems = await _repository.getByUser(_loadEntityId, params);
      } else {
        newItems = await _repository.getByWarehouse(_loadEntityId, params);
      }
      final limit = _currentParams.limit ?? 20;
      emit(current.copyWith(
        changes: [...current.changes, ...newItems],
        hasMore: newItems.length >= limit,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
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
