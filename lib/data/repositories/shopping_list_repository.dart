import '../datasources/shopping_list_remote_datasource.dart';
import '../models/shopping_list_item_model.dart';

class ShoppingListRepository {
  final ShoppingListRemoteDatasource _datasource;
  ShoppingListRepository(this._datasource);

  Future<List<ShoppingListItemModel>> generate(int warehouseId) =>
      _datasource.generate(warehouseId);

  Future<List<ShoppingListItemModel>> getList(int warehouseId) =>
      _datasource.getList(warehouseId);

  Future<List<ShoppingListItemModel>> addItem(
          int warehouseId, int productId, double qty) =>
      _datasource.addItem(warehouseId, productId, qty);

  Future<List<ShoppingListItemModel>> updateItem(int id, double newQty) =>
      _datasource.updateItem(id, newQty);

  Future<void> removeItem(int id) => _datasource.removeItem(id);

  Future<void> clearList(int warehouseId) =>
      _datasource.clearList(warehouseId);
}
