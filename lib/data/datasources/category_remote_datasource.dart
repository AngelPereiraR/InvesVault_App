import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../../core/constants/api_constants.dart';

class CategoryRemoteDatasource {
  final Dio _dio;
  CategoryRemoteDatasource(this._dio);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return (response.data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> createCategory(String name) async {
    final response =
        await _dio.post(ApiConstants.categories, data: {'name': name});
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory(int id, String name) async {
    final response =
        await _dio.put(ApiConstants.categoryById(id), data: {'name': name});
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) =>
      _dio.delete(ApiConstants.categoryById(id));
}
