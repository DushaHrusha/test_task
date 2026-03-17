// lib/data/services/auth_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:test_task/user_model.dart';

/// Сервис авторизации
///
/// Поддерживает:
/// - Google Sign-In
/// - Apple Sign-In
/// - Сохранение токена в secure storage
/// - Автоматическое добавление токена к запросам
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final GoogleSignIn _googleSignIn;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  UserModel? _currentUser;
  String? _token;

  AuthService({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
      _storage = const FlutterSecureStorage(),
      _googleSignIn = GoogleSignIn.instance {
    // ✅ Обновлённый interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // ✅ Проверяем тип ошибки
          final isNetworkError =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;

          // ✅ Логаутим ТОЛЬКО если это 401 И НЕ проблема с интернетом
          if (error.response?.statusCode == 401 && !isNetworkError) {
            debugPrint('❌ 401 Unauthorized - token expired, logging out');
            await logout();
          } else if (isNetworkError) {
            debugPrint('⚠️ Network error (не логаутим): ${error.message}');
          }

          handler.next(error);
        },
      ),
    );
  }

  /// Текущий пользователь
  UserModel? get currentUser => _currentUser;

  /// Авторизован?
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Получить токен из storage
  Future<String?> getToken() async {
    _token ??= await _storage.read(key: _tokenKey);
    return _token;
  }

  /// Инициализация - проверяем сохранённую сессию
  Future<bool> initialize() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      final userData = await _storage.read(key: _userKey);

      if (_token != null && userData != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userData));

        // Проверяем валидность токена
        final isValid = await _validateToken();
        if (!isValid) {
          await logout();
          return false;
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      return false;
    }
  }

  /// Проверка валидности токена
  Future<bool> _validateToken() async {
    try {
      final response = await _dio.get('/v1/auth/user');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Обновляем данные пользователя
        _currentUser = UserModel.fromJson(response.data['data']['user']);
        await _storage.write(
          key: _userKey,
          value: jsonEncode(_currentUser!.toJson()),
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  /// Авторизация через Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Начинаем Google Sign-In flow
      //final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // if (googleUser == null) {
      //   return AuthResult.cancelled();
      // }

      // // Получаем auth details
      // final GoogleSignInAuthentication googleAuth =
      //     await googleUser.authentication;

      // if (googleAuth.accessToken == null) {
      //   return AuthResult.error('Failed to get Google access token');
      // }

      // Получаем название устройства
      final deviceName = await _getDeviceName();

      // Отправляем токен на сервер
      final response = await _dio.post(
        '/v1/auth/google',
        data: {
          //   'access_token': googleAuth.accessToken,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      }

      return AuthResult.error(
        response.data['message'] ?? 'Google sign in failed',
      );
    } on DioException catch (e) {
      debugPrint('Google sign in DioError: ${e.message}');
      return AuthResult.error(_handleDioError(e));
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return AuthResult.error('Google sign in failed: $e');
    }
  }

  /// Авторизация через Apple
  Future<AuthResult> signInWithApple() async {
    try {
      // Проверяем доступность Apple Sign-In
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return AuthResult.error(
          'Apple Sign In is not available on this device',
        );
      }

      // Начинаем Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        return AuthResult.error('Failed to get Apple identity token');
      }

      // Собираем полное имя (Apple отдаёт только при первой авторизации)
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = [
          credential.givenName,
          credential.familyName,
        ].where((s) => s != null && s.isNotEmpty).join(' ');
      }

      // Получаем название устройства
      final deviceName = await _getDeviceName();

      // Отправляем данные на сервер
      final response = await _dio.post(
        '/v1/auth/apple',
        data: {
          'identity_token': credential.identityToken,
          'authorization_code': credential.authorizationCode,
          'user_identifier': credential.userIdentifier,
          'email': credential.email,
          'full_name': fullName,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      }

      return AuthResult.error(
        response.data['message'] ?? 'Apple sign in failed',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.cancelled();
      }
      debugPrint('Apple sign in authorization error: ${e.message}');
      return AuthResult.error('Apple sign in failed: ${e.message}');
    } on DioException catch (e) {
      debugPrint('Apple sign in DioError: ${e.message}');
      return AuthResult.error(_handleDioError(e));
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return AuthResult.error('Apple sign in failed: $e');
    }
  }

  /// Обработка успешной авторизации
  Future<AuthResult> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      final userData = data['data']['user'];
      final token = data['data']['token'];

      _currentUser = UserModel.fromJson(userData);
      _token = token;

      // Сохраняем в secure storage
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(userData));

      return AuthResult.success(_currentUser!);
    } catch (e) {
      debugPrint('Handle auth success error: $e');
      return AuthResult.error('Failed to process authentication response');
    }
  }

  /// Выход
  Future<void> logout() async {
    try {
      // Пытаемся уведомить сервер
      if (_token != null) {
        try {
          await _dio.post('/v1/auth/logout');
        } catch (e) {
          debugPrint('Logout API error (ignored): $e');
        }
      }

      // Выходим из Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google sign out error (ignored): $e');
      }

      // Очищаем локальные данные
      _token = null;
      _currentUser = null;
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Получить название устройства
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return '${android.brand} ${android.model}';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.name;
      }

      return 'Unknown Device';
    } catch (e) {
      return 'Mobile App';
    }
  }

  /// Обработка Dio ошибок
  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection';
    }

    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }

    return 'Authentication failed. Please try again.';
  }
}

/// Результат авторизации
class AuthResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final UserModel? user;

  AuthResult._({
    required this.success,
    this.cancelled = false,
    this.error,
    this.user,
  });

  factory AuthResult.success(UserModel user) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, error: message);

  factory AuthResult.cancelled() =>
      AuthResult._(success: false, cancelled: true);
}
