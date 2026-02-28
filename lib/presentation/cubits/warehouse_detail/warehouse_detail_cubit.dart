import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/notification_service.dart';
import '../../../data/models/warehouse_model.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/stock_change_repository.dart';
import '../../../data/repositories/warehouse_product_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';

part 'warehouse_detail_state.dart';

class WarehouseDetailCubit extends Cubit<WarehouseDetailState> {
  final WarehouseRepository _warehouseRepository;
  final WarehouseProductRepository _warehouseProductRepository;
  final StockChangeRepository _stockChangeRepository;
  final NotificationService _notificationService;

  WarehouseDetailCubit(
    this._warehouseRepository,
    this._warehouseProductRepository,
    this._stockChangeRepository,
    this._notificationService,
  ) : super(const WarehouseDetailInitial());

  Future<void> load(int warehouseId) async {
    emit(const WarehouseDetailLoading());
    try {
      final warehouse =
          await _warehouseRepository.getWarehouseById(warehouseId);
      final products =
          await _warehouseProductRepository.getProducts(warehouseId);
      emit(WarehouseDetailLoaded(
        warehouse: warehouse,
        products: products,
        filtered: products,
      ));
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! WarehouseDetailLoaded) return;
    final filtered = query.isEmpty
        ? current.products
        : current.products
            .where((p) =>
                p.product?.name
                    .toLowerCase()
                    .contains(query.toLowerCase()) ??
                false)
            .toList();
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
    try {
      await _stockChangeRepository.create({
        'product_id': productId,
        'warehouse_id': warehouseId,
        'change_quantity': delta.abs(),
        'change_type': delta >= 0 ? 'entrada' : 'salida',
        if (reason != null) 'reason': reason,
        'user_id': userId,
      });
      // Reload products to get fresh quantities
      final products = await _warehouseProductRepository
          .getProducts(warehouseId);
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
      final filtered = current.query.isEmpty
          ? products
          : products
              .where((p) =>
                  p.product?.name
                      .toLowerCase()
                      .contains(current.query.toLowerCase()) ??
                  false)
              .toList();
      emit(current.copyWith(products: products, filtered: filtered));
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
    }
  }

  Future<void> removeProduct(int id, int warehouseId) async {
    try {
      await _warehouseProductRepository.deleteProduct(id);
      await load(warehouseId);
    } catch (e) {
      emit(WarehouseDetailError(e.toString()));
    }
  }
}
