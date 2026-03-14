import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class DioClient {
  static Dio? _instance;

  static Dio getInstance(StorageService storageService) {
    _instance ??= _createDio(storageService);
    return _instance!;
  }

  static Dio _createDio(StorageService storageService) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          // Add APP_API_KEY header when provided at compile time
          if (ApiConstants.appApiKey.isNotEmpty) 'x-api-key': ApiConstants.appApiKey,
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Ensure x-api-key is always present for requests when set
          if (ApiConstants.appApiKey.isNotEmpty) {
            options.headers['x-api-key'] = ApiConstants.appApiKey;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Silently rotate token when the backend issues a refreshed one
          final refreshed =
              response.headers.value('x-refreshed-token');
          if (refreshed != null && refreshed.isNotEmpty) {
            await storageService.saveToken(refreshed);
            await storageService.saveLastActive();
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await storageService.clearAll();
          }
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }

    return dio;
  }

  // Reset singleton (useful for logout)
  static void reset() => _instance = null;
}
