import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    hide Options;

class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  final TokenStorage tokenStorage; // ← добавили зависимость

  ApiClient({
    required this.baseUrl,
    required this.tokenStorage, // ← инжектим
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await tokenStorage.clearToken();
          }
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  Dio get dio => _dio;

  // GET запрос
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST запрос
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT запрос
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE запрос
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Обработка ошибок
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.badResponse:
        return ServerException(
          'Server error: ${error.response?.statusCode}',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return NetworkException('Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      default:
        return NetworkException('Unexpected error occurred');
    }
  }
}

// Кастомные исключения
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

abstract class TokenStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
  Future<bool> needsRevalidation();
  Future<bool> hasToken();
}

class TokenLocalDataSource implements TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _lastValidatedKey = 'token_last_validated';

  String? _cachedToken;
  DateTime? _lastValidated;

  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _lastValidated = DateTime.now();

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(
      key: _lastValidatedKey,
      value: _lastValidated!.toIso8601String(),
    );
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    _lastValidated = null;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _lastValidatedKey);
  }

  // ✅ Проверка нужна ли повторная валидация
  Future<bool> needsRevalidation() async {
    if (_lastValidated != null) {
      final duration = DateTime.now().difference(_lastValidated!);
      // Ревалидация нужна если прошло больше 1 часа
      return duration.inHours >= 1;
    }

    final lastValidatedStr = await _storage.read(key: _lastValidatedKey);
    if (lastValidatedStr != null) {
      _lastValidated = DateTime.parse(lastValidatedStr);
      final duration = DateTime.now().difference(_lastValidated!);
      return duration.inHours >= 1;
    }

    return true; // Нет данных о валидации - нужна проверка
  }
}
