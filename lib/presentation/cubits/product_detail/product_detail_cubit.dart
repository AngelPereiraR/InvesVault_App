import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/notification_service.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/stock_change_repository.dart';
import '../../../data/repositories/warehouse_product_repository.dart';

part 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final WarehouseProductRepository _warehouseProductRepository;
  final StockChangeRepository _stockChangeRepository;
  final NotificationService _notificationService;

  ProductDetailCubit(
    this._warehouseProductRepository,
    this._stockChangeRepository,
    this._notificationService,
  ) : super(const ProductDetailInitial());

  Future<void> load(int warehouseId, int warehouseProductId) async {
    emit(const ProductDetailLoading());
    try {
      final products =
          await _warehouseProductRepository.getProducts(warehouseId);
      final wp = products.firstWhere((p) => p.id == warehouseProductId);
      emit(ProductDetailLoaded(wp));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }

  Future<void> updateDetails(Map<String, dynamic> data) async {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    final wp = current.warehouseProduct;
    emit(ProductDetailUpdating(wp));
    try {
      final updated =
          await _warehouseProductRepository.updateProduct(wp.id, data);
      emit(ProductDetailLoaded(updated));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }

  Future<void> quickUpdate({
    required double delta,
    required int userId,
    String? reason,
  }) async {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    final wp = current.warehouseProduct;
    if (delta == 0) return;
    emit(ProductDetailUpdating(wp));
    try {
      await _stockChangeRepository.create({
        'product_id': wp.productId,
        'warehouse_id': wp.warehouseId,
        'change_quantity': delta.abs().toInt(),
        'change_type': delta > 0 ? 'inbound' : 'outbound',
        if (reason != null) 'reason': reason,
        'user_id': userId,
      });
      final products =
          await _warehouseProductRepository.getProducts(wp.warehouseId);
      final updated =
          products.firstWhere((p) => p.id == wp.id, orElse: () => wp);
      if (updated.isLowStock && updated.product != null) {
        await _notificationService.showLowStockNotification(
          id: updated.id,
          productName: updated.product!.name,
          currentQuantity: updated.quantity,
          minQuantity: updated.minQuantity ?? 0,
        );
      }
      emit(ProductDetailLoaded(updated));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }
}
