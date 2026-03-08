import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  WarehouseDetailCubit(
    this._warehouseRepository,
    this._warehouseProductRepository,
    this._stockChangeRepository,
    this._notificationService,
    this._warehouseUserRepository,
  ) : super(const WarehouseDetailInitial());

  List<WarehouseProductModel> _applySearch(
    List<WarehouseProductModel> products,
    String query,
  ) {
    if (query.isEmpty) return products;
    return products
        .where((p) =>
            p.product?.name.toLowerCase().contains(query.toLowerCase()) ??
            false)
        .toList();
  }

  List<int> _withUpdatingId(List<int> ids, int productId) {
    if (ids.contains(productId)) return ids;
    return [...ids, productId];
  }

  List<int> _withoutUpdatingId(List<int> ids, int productId) =>
      ids.where((id) => id != productId).toList();

  Future<void> load(int warehouseId, {required int userId}) async {
    _lastUserId = userId;
    emit(const WarehouseDetailLoading());
    try {
      final warehouse =
          await _warehouseRepository.getWarehouseById(warehouseId);
      final products =
          await _warehouseProductRepository.getProducts(warehouseId);

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

      emit(WarehouseDetailLoaded(
        warehouse: warehouse,
        products: products,
        filtered: products,
        currentUserRole: userRole,
      ));
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    final filtered = _applySearch(current.products, query);
    emit(current.copyWith(filtered: filtered, query: query));
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
          await _warehouseProductRepository.getProducts(warehouseId);
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
      final filtered = _applySearch(products, current.query);
      emit(current.copyWith(
        products: products,
        filtered: filtered,
        updatingProductIds: _withoutUpdatingId(
          current.updatingProductIds,
          warehouseProductId,
        ),
      ));
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
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
          await _warehouseProductRepository.getProducts(warehouseId);
      emit(current.copyWith(
        products: products,
        filtered: _applySearch(products, current.query),
        updatingProductIds: _withoutUpdatingId(current.updatingProductIds, id),
      ));
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
    }
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    try {
      await _warehouseProductRepository.addProduct(data);
      await load(current.warehouse.id, userId: _lastUserId);
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
    }
  }
}
