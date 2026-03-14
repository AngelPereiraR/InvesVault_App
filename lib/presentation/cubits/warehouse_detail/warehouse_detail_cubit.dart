import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/filter_params.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/warehouse_model.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/stock_change_repository.dart';
import '../../../data/repositories/warehouse_product_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';
import '../../../data/repositories/warehouse_user_repository.dart';

part 'warehouse_detail_state.dart';

class WarehouseDetailCubit extends Cubit<WarehouseDetailState> {
  final WarehouseRepository _warehouseRepository;
  final WarehouseProductRepository _warehouseProductRepository;
  final StockChangeRepository _stockChangeRepository;
  final NotificationService _notificationService;
  final WarehouseUserRepository _warehouseUserRepository;
  int _lastUserId = 0;
  int _lastWarehouseId = 0;
  FilterParams _currentParams = FilterParams.empty;

  WarehouseDetailCubit(
    this._warehouseRepository,
    this._warehouseProductRepository,
    this._stockChangeRepository,
    this._notificationService,
    this._warehouseUserRepository,
  ) : super(const WarehouseDetailInitial());

  List<int> _withUpdatingId(List<int> ids, int productId) {
    if (ids.contains(productId)) return ids;
    return [...ids, productId];
  }

  List<int> _withoutUpdatingId(List<int> ids, int productId) =>
      ids.where((id) => id != productId).toList();

  Future<void> load(int warehouseId, {required int userId, FilterParams params = FilterParams.empty}) async {
    _lastUserId = userId;
    _lastWarehouseId = warehouseId;
    _currentParams = params;
    emit(const WarehouseDetailLoading());
    try {
      final warehouse =
          await _warehouseRepository.getWarehouseById(warehouseId);
      final products =
          await _warehouseProductRepository.getProducts(warehouseId, params);

      // Determine current user's role for this warehouse
      String userRole = 'viewer';
      if (warehouse.ownerId == userId) {
        userRole = 'admin';
      } else {
        try {
          final users = await _warehouseUserRepository.getUsers(warehouseId);
          final entry = users.where((u) => u.userId == userId);
          if (entry.isNotEmpty) userRole = entry.first.role;
        } catch (_) {}
      }

      final limit = params.limit ?? 20;
      emit(WarehouseDetailLoaded(
        warehouse: warehouse,
        products: products,
        filtered: products,
        currentUserRole: userRole,
        hasMore: products.length >= limit,
        currentPage: 1,
      ));
    } catch (e) {
      emit(WarehouseDetailError(friendlyError(e)));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final params = _currentParams.copyWith(page: nextPage);
      final newItems = await _warehouseProductRepository.getProducts(
          _lastWarehouseId, params);
      final limit = _currentParams.limit ?? 20;
      emit(current.copyWith(
        products: [...current.products, ...newItems],
        filtered: [...current.filtered, ...newItems],
        hasMore: newItems.length >= limit,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(WarehouseDetailError(friendlyError(e)));
    }
  }

  void search(String query) {
    final newParams = FilterParams(
      search: query.isEmpty ? null : query,
      limit: _currentParams.limit,
    );
    load(_lastWarehouseId, userId: _lastUserId, params: newParams);
  }

  Future<void> quickUpdate({
    required int warehouseProductId,
    required int productId,
    required int warehouseId,
    required int userId,
    required double delta,
    String? reason,
  }) async {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    emit(current.copyWith(
      updatingProductIds: _withUpdatingId(
        current.updatingProductIds,
        warehouseProductId,
      ),
    ));
    try {
      await _stockChangeRepository.create({
        'product_id': productId,
        'warehouse_id': warehouseId,
        'change_quantity': delta.abs(),
        'change_type': delta >= 0 ? 'inbound' : 'outbound',
        if (reason != null) 'reason': reason,
        'user_id': userId,
      });
      // Reload products to get fresh quantities
      final products =
          await _warehouseProductRepository.getProducts(warehouseId, _currentParams);
      final updatedWp = products.firstWhere(
        (p) => p.id == warehouseProductId,
        orElse: () => current.products.firstWhere(
          (p) => p.id == warehouseProductId,
        ),
      );
      if (updatedWp.isLowStock && updatedWp.product != null) {
        await _notificationService.showLowStockNotification(
          id: updatedWp.id,
          productName: updatedWp.product!.name,
          currentQuantity: updatedWp.quantity,
          minQuantity: updatedWp.minQuantity ?? 0,
        );
      }
      emit(current.copyWith(
        products: products,
        filtered: products,
        updatingProductIds: _withoutUpdatingId(
          current.updatingProductIds,
          warehouseProductId,
        ),
      ));
    } catch (e) {
      emit(WarehouseDetailError(friendlyError(e)));
    }
  }

  Future<void> removeProduct(int id, int warehouseId) async {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    emit(current.copyWith(
      updatingProductIds: _withUpdatingId(current.updatingProductIds, id),
    ));
    try {
      await _warehouseProductRepository.deleteProduct(id);
      final products =
          await _warehouseProductRepository.getProducts(warehouseId, _currentParams);
      emit(current.copyWith(
        products: products,
        filtered: products,
        updatingProductIds: _withoutUpdatingId(current.updatingProductIds, id),
      ));
    } catch (e) {
      emit(WarehouseDetailError(friendlyError(e)));
    }
  }

  Future<void> removeProducts(List<int> ids, int warehouseId) async {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    emit(current.copyWith(isDeleting: true));
    try {
      for (final id in ids) {
        await _warehouseProductRepository.deleteProduct(id);
      }
    } catch (e) {
      emit(WarehouseDetailError(friendlyError(e)));
      return;
    }
    final products =
        await _warehouseProductRepository.getProducts(warehouseId, _currentParams);
    emit(current.copyWith(
      products: products,
      filtered: products,
      isDeleting: false,
    ));
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    try {
      await _warehouseProductRepository.addProduct(data);
      await load(current.warehouse.id, userId: _lastUserId, params: _currentParams);
    } catch (e) {
      emit(WarehouseDetailError(friendlyError(e)));
    }
  }
}
