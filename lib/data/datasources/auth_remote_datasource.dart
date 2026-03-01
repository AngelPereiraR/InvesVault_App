import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

class AuthRemoteDatasource {
  final Dio _dio;
  AuthRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiConstants.register, data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> updateUser(
      int id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.userById(id), data: data);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel?> searchByEmail(String email) async {
    try {
      final response =
          await _dio.get(ApiConstants.userByEmail(email));
      debugPrint('[searchByEmail] status=${response.statusCode} data=${response.data}');
      final data = response.data;
      if (data == null) return null;
      // API may return a single object or a list
      if (data is List) {
        if (data.isEmpty) return null;
        return UserModel.fromJson(data.first as Map<String, dynamic>);
      }
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[searchByEmail] DioError status=${e.response?.statusCode} data=${e.response?.data}');
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
