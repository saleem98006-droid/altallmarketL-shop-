import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../utils/token_manager.dart';
import 'package:flutter/foundation.dart';


class DioService {
  static bool _isInitialized = false;
  static const String _authRetryKey = '__auth_retry_done__';
  static const String _networkRetryKey = '__network_retry_done__';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Singleton
  static Dio get instance => _dio;

  // تهيئة Interceptors
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // إضافة التوكن تلقائياً
        final token = await TokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },

      onResponse: (response, handler) {
        return handler.next(response);
      },

      onError: (DioException e, handler) async {
        final hasAuthRetried = e.requestOptions.extra[_authRetryKey] == true;
        final hasNetworkRetried =
            e.requestOptions.extra[_networkRetryKey] == true;

        // إذا انتهت صلاحية التوكن
        if (e.response?.statusCode == 401 && !hasAuthRetried) {
          final refreshed = await _refreshToken();

          if (refreshed) {
            // إعادة إرسال الطلب الأصلي
            e.requestOptions.extra[_authRetryKey] = true;
            final newRequest = await _retryRequest(e.requestOptions);
            return handler.resolve(newRequest);
          }
        }

        // إعادة المحاولة عند فشل الاتصال (فقط للطلبات الآمنة)
        if (_shouldRetry(e.requestOptions, e) && !hasNetworkRetried) {
          try {
            e.requestOptions.extra[_networkRetryKey] = true;
            final retryResponse = await _retryRequest(e.requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {}
        }

        return handler.next(e);
      },
    ));

   // Logging (Debug only)
    if (!kReleaseMode) {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));}
  }

  // هل يجب إعادة المحاولة؟
  static bool _shouldRetry(RequestOptions requestOptions, DioException e) {
    final method = requestOptions.method.toUpperCase();
    final isSafeMethod = method == 'GET' || method == 'HEAD';

    if (!isSafeMethod) {
      return false;
    }

    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  // إعادة إرسال الطلب
  static Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // تجديد التوكن
  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post('/Auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        final newRefresh = response.data['refreshToken'];

        await TokenManager.saveToken(newToken);
        await TokenManager.saveRefreshToken(newRefresh);

        return true;
      }
    } catch (_) {}

    return false;
  }

  // GET
  static Future<Response> get(String path,
      {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  // POST
  static Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // PUT
  static Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // DELETE
  static Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}