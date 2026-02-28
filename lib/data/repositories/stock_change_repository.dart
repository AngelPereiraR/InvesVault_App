import '../datasources/stock_change_remote_datasource.dart';
import '../models/stock_change_model.dart';

class StockChangeRepository {
  final StockChangeRemoteDatasource _datasource;
  StockChangeRepository(this._datasource);

  Future<StockChangeModel> create(Map<String, dynamic> data) =>
      _datasource.create(data);

  Future<List<StockChangeModel>> getByProduct(int productId) =>
      _datasource.getByProduct(productId);

  Future<List<StockChangeModel>> getByWarehouse(int warehouseId) =>
      _datasource.getByWarehouse(warehouseId);

  Future<List<StockChangeModel>> getByUser(int userId) =>
      _datasource.getByUser(userId);
}
