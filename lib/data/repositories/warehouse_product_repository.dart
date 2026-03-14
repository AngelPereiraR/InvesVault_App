import '../datasources/warehouse_product_remote_datasource.dart';
import '../models/warehouse_product_model.dart';
import '../../core/models/filter_params.dart';

class WarehouseProductRepository {
  final WarehouseProductRemoteDatasource _datasource;
  WarehouseProductRepository(this._datasource);

  Future<List<WarehouseProductModel>> getProducts(int warehouseId, [FilterParams params = FilterParams.empty]) =>
      _datasource.getProducts(warehouseId, params);

  Future<List<WarehouseProductModel>> getLowStock(int warehouseId) =>
      _datasource.getLowStock(warehouseId);

  Future<WarehouseProductModel> addProduct(Map<String, dynamic> data) =>
      _datasource.addProduct(data);

  Future<WarehouseProductModel> updateProduct(
          int id, Map<String, dynamic> data) =>
      _datasource.updateProduct(id, data);

  Future<void> deleteProduct(int id) => _datasource.deleteProduct(id);
}
