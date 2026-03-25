import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/filter_params.dart';
import '../../../data/repositories/warehouse_product_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';
import '../../../data/repositories/product_repository.dart';
import 'add_product_to_warehouse_state.dart';

class AddProductToWarehouseCubit extends Cubit<AddProductToWarehouseState> {
  final WarehouseProductRepository warehouseProductRepository;
  final WarehouseRepository warehouseRepository;
  final ProductRepository productRepository;

  AddProductToWarehouseCubit({
    required this.warehouseProductRepository,
    required this.warehouseRepository,
    required this.productRepository,
  }) : super(const AddProductToWarehouseInitial());

  /// Load available warehouses for this product
  /// Filters:
  /// - Only warehouses where user has editor+ permissions
  /// - Excludes warehouses that already contain this product
  /// - Gets default unit from product catalog
  Future<void> init(int productId) async {
    try {
      emit(const AddProductToWarehouseLoading());

      // Get product to retrieve default unit
      final product = await productRepository.getProductById(productId);
      final productUnit = product.defaultUnit;

      // Get all user warehouses
      final warehouses = await warehouseRepository.getWarehouses(
        const FilterParams(
          page: 1,
          limit: 500, // Get all
        ),
      );

      // Get warehouses that already have this product
      final warehouseProductsList =
          await warehouseProductRepository.getWarehousesByProduct(productId);
      final warehouseIdsWithProduct =
          warehouseProductsList.map((wp) => wp.warehouseId).toSet();

      // Filter: only include warehouses without this product
      // Note: Full permission check happens at API level
      final availableWarehouses = warehouses
          .where((w) => !warehouseIdsWithProduct.contains(w.id))
          .toList();

      emit(AddProductToWarehouseReady(
        warehouses: availableWarehouses,
        productUnit: productUnit,
        productId: productId,
      ));
    } catch (e) {
      emit(AddProductToWarehouseError(
        e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Add product to warehouse with initial stock
  Future<void> addProductToWarehouse({
    required int warehouseId,
    required int quantity,
    required double? price,
    required int minStock,
    required int productId,
    String? observations,
  }) async {
    try {
      emit(const AddProductToWarehouseLoading());

      await warehouseProductRepository.addWarehouseProduct(
        warehouseId: warehouseId,
        productId: productId,
        quantity: quantity,
        price: price,
        minStock: minStock,
        observations: observations,
      );

      emit(const AddProductToWarehouseSuccess());
    } catch (e) {
      emit(AddProductToWarehouseError(
        e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
