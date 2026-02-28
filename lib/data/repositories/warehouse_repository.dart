import '../datasources/warehouse_remote_datasource.dart';
import '../models/warehouse_model.dart';

class WarehouseRepository {
  final WarehouseRemoteDatasource _datasource;
  WarehouseRepository(this._datasource);

  Future<List<WarehouseModel>> getWarehouses() =>
      _datasource.getWarehouses();

  Future<WarehouseModel> getWarehouseById(int id) =>
      _datasource.getWarehouseById(id);

  Future<WarehouseModel> createWarehouse({
    required String name,
    required int ownerId,
    bool isShared = false,
  }) =>
      _datasource.createWarehouse(
          name: name, ownerId: ownerId, isShared: isShared);

  Future<WarehouseModel> updateWarehouse(
          int id, Map<String, dynamic> data) =>
      _datasource.updateWarehouse(id, data);

  Future<void> deleteWarehouse(int id) => _datasource.deleteWarehouse(id);
}
