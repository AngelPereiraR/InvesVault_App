import 'package:dio/dio.dart';
import '../models/shopping_list_item_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/filter_params.dart';

class ShoppingListRemoteDatasource {
  final Dio _dio;
  ShoppingListRemoteDatasource(this._dio);

  Future<List<ShoppingListItemModel>> generateAll() async {
    final response = await _dio.post(ApiConstants.shoppingListGenerateAll);
    return (response.data as List)
        .map((e) =>
            ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShoppingListItemModel>> generate(int warehouseId) async {
    final response =
        await _dio.post(ApiConstants.shoppingListGenerate(warehouseId));
    return (response.data as List)
        .map((e) =>
            ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShoppingListItemModel>> getList(int warehouseId, [FilterParams params = FilterParams.empty]) async {
    final response = await _dio.get(
      ApiConstants.shoppingList(warehouseId),
      queryParameters: params.toQueryParameters(),
    );
    return (response.data as List)
        .map((e) =>
            ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShoppingListItemModel>> addItem(
      int warehouseId, int productId, double qty) async {
    final response = await _dio.post(
      ApiConstants.shoppingListAdd(warehouseId),
      data: {'product_id': productId, 'suggested_qty': qty},
    );
    return (response.data as List)
        .map((e) =>
            ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShoppingListItemModel>> updateItem(
      int id, double newQty) async {
    final response = await _dio.patch(
      ApiConstants.shoppingListUpdate(id),
      data: {'suggested_qty': newQty},
    );
    return (response.data as List)
        .map((e) =>
            ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeItem(int id) =>
      _dio.delete(ApiConstants.shoppingListRemove(id));

  Future<void> clearList(int warehouseId) =>
      _dio.delete(ApiConstants.shoppingListClear(warehouseId));

  Future<List<ShoppingListItemModel>> getAllItems([FilterParams params = FilterParams.empty]) async {
    final response = await _dio.get(
      ApiConstants.shoppingListAll,
      queryParameters: params.toQueryParameters(),
    );
    return (response.data as List)
        .map((e) =>
            ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
