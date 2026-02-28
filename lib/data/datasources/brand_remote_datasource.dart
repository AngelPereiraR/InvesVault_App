import 'package:dio/dio.dart';
import '../models/brand_model.dart';
import '../../core/constants/api_constants.dart';

class BrandRemoteDatasource {
  final Dio _dio;
  BrandRemoteDatasource(this._dio);

  Future<List<BrandModel>> getBrands() async {
    final response = await _dio.get(ApiConstants.brands);
    return (response.data as List)
        .map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BrandModel> createBrand(String name) async {
    final response =
        await _dio.post(ApiConstants.brands, data: {'name': name});
    return BrandModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BrandModel> updateBrand(int id, String name) async {
    final response =
        await _dio.put(ApiConstants.brandById(id), data: {'name': name});
    return BrandModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBrand(int id) =>
      _dio.delete(ApiConstants.brandById(id));
}
