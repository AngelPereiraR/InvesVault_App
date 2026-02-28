import '../datasources/warehouse_user_remote_datasource.dart';
import '../models/warehouse_user_model.dart';

class WarehouseUserRepository {
  final WarehouseUserRemoteDatasource _datasource;
  WarehouseUserRepository(this._datasource);

  Future<List<WarehouseUserModel>> getUsers(int warehouseId) =>
      _datasource.getUsers(warehouseId);

  Future<WarehouseUserModel> addUser(
          int warehouseId, int userId, String role) =>
      _datasource.addUser(warehouseId, userId, role);

  Future<WarehouseUserModel> updateRole(
          int warehouseId, int userId, String role) =>
      _datasource.updateRole(warehouseId, userId, role);

  Future<void> removeUser(int warehouseId, int userId) =>
      _datasource.removeUser(warehouseId, userId);
}
