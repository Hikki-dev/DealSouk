import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dealsouk/features/auth/data/auth_service.dart';

class ApiClient {
  late final Dio _dio;

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get _resolvedBaseUrl {
    if (_envBaseUrl.isEmpty) {
      if (kReleaseMode) {
        throw StateError(
          'API_BASE_URL must be defined via --dart-define in release mode. '
          'Production builds must not have a hardcoded Render URL fallback.',
        );
      }
      return 'http://localhost:3000';
    }
    return _envBaseUrl;
  }

  ApiClient() {
    final baseUrl = _resolvedBaseUrl;
    if (kReleaseMode && !baseUrl.startsWith('https://')) {
      throw StateError(
        'Release builds must use secure HTTPS connections. Base URL was $baseUrl',
      );
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Retry once with a fresh token on 401
          if (error.response?.statusCode == 401) {
            final token = await authService.getIdToken(forceRefresh: true);
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (_) {}
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  String get baseUrl => _resolvedBaseUrl;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? params,
    Options? options,
  }) => _dio.get(path, queryParameters: params, options: options);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

final apiClient = ApiClient();
