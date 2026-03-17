import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_task/user_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../api_client.dart';
import '../../api_endpoints.dart';

abstract class AuthRepository {
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<AuthResult> signInWithPhone(String phoneNumber);
  Future<AuthResult> verifyPhoneCode(String phoneNumber, String code);
  Future<AuthResult> loginWithPassword({
    required String phone,
    required String password,
  });
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<bool> validateToken();
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Future<void> logoutFromAllDevices();
}

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  AuthResult({required this.success, this.user, this.error});

  factory AuthResult.success(UserModel user) =>
      AuthResult(success: true, user: user);
  factory AuthResult.error(String error) =>
      AuthResult(success: false, error: error);
  factory AuthResult.cancelled() =>
      AuthResult(success: false, error: 'Cancelled');
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;

  UserModel? _currentUser;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage,
       _googleSignIn = GoogleSignIn.instance;

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      //    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // if (googleUser == null) {
      //   return AuthResult.cancelled();
      // }

      //  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      // if (googleAuth.accessToken == null) {
      //   return AuthResult.error('Failed to get Google access token');
      // }

      final deviceName = await _getDeviceName();

      final response = await _apiClient.post(
        ApiEndpoints.googleAuth,
        data: {
          // 'access_token': googleAuth.accessToken,
          'device_name': deviceName,
        },
      );

      if (response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Google sign in failed',
        );
      }
    } on DioException catch (e) {
      return AuthResult.error(_handleDioError(e));
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return AuthResult.error('Google sign in failed');
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return AuthResult.error('Apple Sign In is not available');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        return AuthResult.error('Failed to get Apple identity token');
      }

      final deviceName = await _getDeviceName();

      final response = await _apiClient.post(
        ApiEndpoints.appleAuth,
        data: {
          'identity_token': credential.identityToken,
          'authorization_code': credential.authorizationCode,
          'device_name': deviceName,
        },
      );

      if (response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Apple sign in failed',
        );
      }
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return AuthResult.error('Apple sign in failed');
    }
  }

  @override
  Future<AuthResult> signInWithPhone(String phoneNumber) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendSms,
        data: {'phone': phoneNumber},
      );

      if (response.data['success'] == true) {
        return AuthResult.success(
          UserModel.fromJson(response.data['data']['user']),
        );
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Failed to send SMS',
        );
      }
    } catch (e) {
      return AuthResult.error('Failed to send SMS');
    }
  }

  @override
  Future<AuthResult> verifyPhoneCode(String phoneNumber, String code) async {
    try {
      final deviceName = await _getDeviceName();

      final response = await _apiClient.post(
        ApiEndpoints.verifySms,
        data: {'phone': phoneNumber, 'code': code, 'device_name': deviceName},
      );

      if (response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      } else {
        return AuthResult.error(response.data['message'] ?? 'Invalid code');
      }
    } catch (e) {
      return AuthResult.error('Verification failed');
    }
  }

  @override
  Future<bool> validateToken() async {
    // ✅ Проверяем нужна ли ревалидация
    final needsCheck = await _tokenStorage.needsRevalidation();

    if (!needsCheck && _currentUser != null) {
      debugPrint('✅ Token recently validated, skipping check');
      return true;
    }

    try {
      final response = await _apiClient.get(ApiEndpoints.user);
      if (response.data['success'] == true) {
        _currentUser = UserModel.fromJson(response.data['data']['user']);

        // ✅ Обновляем время валидации
        final token = await _tokenStorage.getToken();
        if (token != null) {
          await _tokenStorage.saveToken(token);
        }

        debugPrint('✅ Token valid for user: ${_currentUser?.email}');
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        debugPrint('❌ Token expired (401)');
        return false;
      }

      final isNetworkError =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout;

      if (isNetworkError && _currentUser != null) {
        debugPrint('⚠️ Network error, but user exists - считаем валидным');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Token validation error: $e');
      return false;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final token = await _tokenStorage.getToken();
    if (token == null) return null;

    final isValid = await validateToken();
    return isValid ? _currentUser : null;
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _tokenStorage.clearToken();
      _currentUser = null;
      await _googleSignIn.signOut();
    }
  }

  @override
  Future<void> logoutFromAllDevices() async {
    try {
      await _apiClient.post(ApiEndpoints.logoutAll);
    } catch (e) {
      debugPrint('Logout all error: $e');
    } finally {
      await _tokenStorage.clearToken();
      _currentUser = null;
      await _googleSignIn.signOut();
    }
  }

  // ===== Private методы =====

  Future<AuthResult> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      final token = data['data']['token'] as String;
      final userData = data['data']['user'] as Map<String, dynamic>;

      // Сохраняем токен
      await _tokenStorage.saveToken(token);

      // Сохраняем пользователя
      _currentUser = UserModel.fromJson(userData);

      debugPrint('✅ Auth successful: ${_currentUser?.email}');
      return AuthResult.success(_currentUser!);
    } catch (e) {
      debugPrint('Error handling auth success: $e');
      return AuthResult.error('Failed to process auth data');
    }
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<AuthResult> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final deviceName = await _getDeviceName();

      final response = await _apiClient.post(
        ApiEndpoints.login, // '/auth/login'
        data: {'phone': phone, 'password': password, 'device_name': deviceName},
      );

      if (response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      } else {
        return AuthResult.error(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      return AuthResult.error(_handleDioError(e));
    } catch (e) {
      debugPrint('Login error: $e');
      return AuthResult.error('Login failed');
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout';
      case DioExceptionType.badResponse:
        return error.response?.data['message'] ?? 'Server error';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return 'Unexpected error occurred';
    }
  }

  @override
  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final deviceName = await _getDeviceName();

      final response = await _apiClient.post(
        ApiEndpoints.register, // '/auth/register'
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'device_name': deviceName,
        },
      );

      if (response.data['success'] == true) {
        return _handleAuthSuccess(response.data);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      return AuthResult.error(_handleDioError(e));
    } catch (e) {
      debugPrint('Registration error: $e');
      return AuthResult.error('Registration failed');
    }
  }
}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial());

  Future<void> initialize() async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        debugPrint('✅ User authenticated: ${user.email}');
        emit(AuthAuthenticated(user: user));
      } else {
        debugPrint('⚠️ No authenticated user');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('⚠️ Auth initialization error: $e');
      // ✅ Не логаутим при ошибке инициализации
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());

    final result = await _authRepository.signInWithGoogle();

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.error != null) {
      emit(AuthError(message: result.error!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithApple() async {
    emit(AuthLoading());

    final result = await _authRepository.signInWithApple();

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.error != null) {
      emit(AuthError(message: result.error!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithPhone(phoneNumber);

    if (result.success) {
      emit(AuthUnauthenticated()); // SMS sent, ждём код
    } else {
      emit(AuthError(message: result.error ?? 'Failed to send SMS'));
    }
  }

  Future<void> verifyPhoneCode(String phoneNumber, String code) async {
    emit(AuthLoading());
    final result = await _authRepository.verifyPhoneCode(phoneNumber, code);

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else {
      emit(AuthError(message: result.error ?? 'Invalid code'));
    }
  }

  Future<void> logout() async {
    debugPrint('🚪 Logging out...');
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    emit(AuthLoading());

    final result = await _authRepository.loginWithPassword(
      phone: phone,
      password: password,
    );

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.error != null) {
      emit(AuthError(message: result.error!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(AuthLoading());

    final result = await _authRepository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(user: result.user!));
    } else if (result.error != null) {
      emit(AuthError(message: result.error!));
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
