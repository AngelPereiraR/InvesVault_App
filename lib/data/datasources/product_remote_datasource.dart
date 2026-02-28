import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../../core/constants/api_constants.dart';

class ProductRemoteDatasource {
  final Dio _dio;
  ProductRemoteDatasource(this._dio);

  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get(ApiConstants.products);
    return (response.data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await _dio.get(ApiConstants.productById(id));
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response =
        await _dio.post(ApiConstants.products, data: data);
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(
      int id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.productById(id), data: data);
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) =>
      _dio.delete(ApiConstants.productById(id));
}
