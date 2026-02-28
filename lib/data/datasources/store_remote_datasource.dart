import 'package:dio/dio.dart';
import '../models/store_model.dart';
import '../../core/constants/api_constants.dart';

class StoreRemoteDatasource {
  final Dio _dio;
  StoreRemoteDatasource(this._dio);

  Future<List<StoreModel>> getStores() async {
    final response = await _dio.get(ApiConstants.stores);
    return (response.data as List)
        .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoreModel> createStore(
      {required String name, String? location}) async {
    final response = await _dio
        .post(ApiConstants.stores, data: {'name': name, 'location': location});
    return StoreModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoreModel> updateStore(int id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.storeById(id), data: data);
    return StoreModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStore(int id) =>
      _dio.delete(ApiConstants.storeById(id));
}
