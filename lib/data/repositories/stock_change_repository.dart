import '../datasources/stock_change_remote_datasource.dart';
import '../models/stock_change_model.dart';
import '../../core/models/filter_params.dart';

class StockChangeRepository {
  final StockChangeRemoteDatasource _datasource;
  StockChangeRepository(this._datasource);

  Future<StockChangeModel> create(Map<String, dynamic> data) =>
      _datasource.create(data);

  Future<List<StockChangeModel>> getByProduct(int productId, [FilterParams params = FilterParams.empty]) =>
      _datasource.getByProduct(productId, params);

  Future<List<StockChangeModel>> getByWarehouse(int warehouseId, [FilterParams params = FilterParams.empty]) =>
      _datasource.getByWarehouse(warehouseId, params);

  Future<List<StockChangeModel>> getByUser(int userId, [FilterParams params = FilterParams.empty]) =>
      _datasource.getByUser(userId, params);
}
