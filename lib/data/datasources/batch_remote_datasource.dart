import 'package:dio/dio.dart';
import '../models/batch_model.dart';
import '../../core/constants/api_constants.dart';

class BatchRemoteDatasource {
  final Dio _dio;
  BatchRemoteDatasource(this._dio);

  Future<List<BatchModel>> getBatches(int warehouseProductId) async {
    try {
      final response = await _dio.get(
        ApiConstants.batchesByWarehouseProduct(warehouseProductId),
      );
      return (response.data as List)
          .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<BatchModel> createBatch(
      int warehouseProductId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiConstants.batchesByWarehouseProduct(warehouseProductId),
      data: data,
    );
    return BatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BatchModel> updateBatch(int id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.batchById(id), data: data);
    return BatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBatch(int id) =>
      _dio.delete(ApiConstants.batchById(id));
}
