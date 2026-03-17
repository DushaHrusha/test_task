// data/repositories/apartments_repository.dart
import 'package:test_task/api_client.dart';
import 'package:test_task/api_endpoints.dart';
import 'package:test_task/data/models/apartment.dart';
import 'package:test_task/data/repositories/apartments_local_data_source.dart';
import 'package:test_task/data/repositories/connectivity_service.dart';

abstract class ApartmentsRepository {
  Future<List<Apartment>> getApartments({bool forceRefresh = false});
  Future<Apartment> getApartmentById(int id);
  Future<List<Apartment>> refreshApartments();
  Future<void> clearCache();
  Future<Map<String, dynamic>> getCacheInfo();
}

class ApartmentsRepositoryImpl implements ApartmentsRepository {
  final ApiClient _apiClient;
  final ApartmentsLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  ApartmentsRepositoryImpl({
    required ApiClient apiClient,
    required ApartmentsLocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  }) : _apiClient = apiClient,
       _localDataSource = localDataSource,
       _connectivityService = connectivityService;

  @override
  Future<List<Apartment>> getApartments({bool forceRefresh = false}) async {
    print('\n🔄 Loading apartments (hybrid strategy)');

    try {
      final hasInternet = await _connectivityService.hasInternetConnection();

      // ✅ СТРАТЕГИЯ 1: Сразу возвращаем кэш (если есть)
      if (!forceRefresh) {
        final cachedApartments = await _localDataSource.getCachedApartments();

        if (cachedApartments.isNotEmpty) {
          print('✅ Showing cached data (${cachedApartments.length} items)');

          // ✅ СТРАТЕГИЯ 2: Параллельно обновляем в фоне (если есть интернет)
          if (hasInternet) {
            _updateCacheInBackground();
          }

          return cachedApartments;
        }
      }

      // ✅ СТРАТЕГИЯ 3: Нет кэша или forceRefresh → загружаем с сервера

      if (!hasInternet) {
        print('❌ No internet and no cache');
        throw NoInternetException('Нет подключения к интернету');
      }

      print('🌐 Fetching from server (no cache or force refresh)');
      return await _fetchFromServerAndCache();
    } catch (e) {
      print('❌ Error: $e');

      // Fallback на кэш при любой ошибке
      final cachedApartments = await _localDataSource.getCachedApartments();
      if (cachedApartments.isNotEmpty) {
        print('📱 Returning cached data as fallback');
        return cachedApartments;
      }

      rethrow;
    }
  }

  @override
  Future<List<Apartment>> refreshApartments() async {
    print('🔄 Force refreshing apartments (pull-to-refresh)');
    return await getApartments(forceRefresh: true);
  }

  // ===== Private методы =====

  /// Загружает с сервера и сохраняет в кэш
  Future<List<Apartment>> _fetchFromServerAndCache() async {
    final response = await _apiClient.get(ApiEndpoints.apartments);

    if (response.data['success'] == true) {
      final responseData = response.data['data'];
      final List data;

      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map && responseData.containsKey('items')) {
        data = responseData['items'] as List;
      } else {
        throw ServerException('Неверный формат данных от сервера');
      }

      final apartments =
          data
              .map((json) => Apartment.fromJson(json as Map<String, dynamic>))
              .toList();

      // Сохраняем в кэш
      await _localDataSource.cacheApartments(apartments);
      print(
        '✅ Data loaded from server and cached (${apartments.length} items)',
      );

      return apartments;
    } else {
      throw ServerException('Не удалось загрузить квартиры');
    }
  }

  /// Обновляет кэш в фоне (не блокирует UI)
  void _updateCacheInBackground() {
    print('🔄 Updating cache in background...');

    _fetchFromServerAndCache()
        .then((apartments) {
          print(
            '✅ Background cache update completed (${apartments.length} items)',
          );
        })
        .catchError((error) {
          print('⚠️ Background cache update failed: $error');
        });
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.clearCache();
  }

  @override
  Future<Map<String, dynamic>> getCacheInfo() async {
    final size = await _localDataSource.getCacheSize();
    final lastUpdate = await _localDataSource.getLastCacheUpdate();
    final isValid = await _localDataSource.isCacheValid();
    return {'size': size, 'lastUpdate': lastUpdate, 'isValid': isValid};
  }

  @override
  Future<Apartment> getApartmentById(int id) async {
    print('\n🔄 Loading apartment #$id');

    try {
      final hasInternet = await _connectivityService.hasInternetConnection();

      // Сначала пытаемся получить из кэша
      final cachedApartment = await _localDataSource.getCachedApartmentById(id);

      // Если нет интернета - возвращаем кэш
      if (!hasInternet) {
        if (cachedApartment != null) {
          print('📱 Returning cached apartment (no internet)');
          return cachedApartment;
        }
        throw NoInternetException('Нет подключения к интернету');
      }

      // Загружаем с сервера
      print('🌐 Fetching apartment from server');
      final response = await _apiClient.get(ApiEndpoints.apartmentById(id));

      if (response.data['success'] == true) {
        final apartment = Apartment.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );

        // Сохраняем в кэш
        await _localDataSource.cacheApartment(apartment);
        print('✅ Apartment loaded and cached');

        return apartment;
      } else {
        throw ServerException('Квартира не найдена');
      }
    } catch (e) {
      print('⚠️ Error loading apartment: $e');

      // Пытаемся вернуть из кэша
      final cachedApartment = await _localDataSource.getCachedApartmentById(id);
      if (cachedApartment != null) {
        print('📱 Returning cached apartment (fallback)');
        return cachedApartment;
      }

      rethrow;
    }
  }

  Future<List<Apartment>> _getFallbackData() async {
    print('🔄 Attempting to load fallback data from cache');
    final cachedApartments = await _localDataSource.getCachedApartments();
    if (cachedApartments.isEmpty) {
      throw CacheException('Нет доступных данных');
    }
    return cachedApartments;
  }
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
  @override
  String toString() => message;
}
