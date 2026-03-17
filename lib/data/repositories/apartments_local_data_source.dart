// data/datasources/apartments_local_datasource.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test_task/data/models/apartment.dart';

class ApartmentsLocalDataSource {
  static const String _boxName = 'apartments_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // ✅ Версия кэша - увеличь до 2 чтобы очистить старые данные
  static const int _cacheVersion = 2;
  static const String _versionKey = 'cache_version';

  /// Получить бокс для квартир
  Future<Box<Map>> _getApartmentsBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      final box = await Hive.openBox<Map>(_boxName);
      await _checkAndMigrateCacheVersion(box);
      return box;
    }
    return Hive.box<Map>(_boxName);
  }

  /// Получить бокс для метаданных
  Future<Box> _getMetadataBox() async {
    if (!Hive.isBoxOpen(_metadataBoxName)) {
      return await Hive.openBox(_metadataBoxName);
    }
    return Hive.box(_metadataBoxName);
  }

  /// ✅ Проверяем версию кэша и очищаем если устарела
  Future<void> _checkAndMigrateCacheVersion(Box box) async {
    try {
      final metadataBox = await _getMetadataBox();
      final currentVersion = metadataBox.get(_versionKey) as int?;

      if (currentVersion == null || currentVersion != _cacheVersion) {
        print(
          '⚠️ Cache version mismatch (current: $currentVersion, required: $_cacheVersion)',
        );
        print('🗑️ Clearing apartments cache...');
        await box.clear();
        await metadataBox.put(_versionKey, _cacheVersion);
        await metadataBox.delete('last_cache_update');
        print('✅ Cache cleared and version updated to $_cacheVersion');
      }
    } catch (e) {
      print('❌ Error checking cache version: $e');
    }
  }

  /// Сохранить список квартир в кэш
  Future<void> cacheApartments(List<Apartment> apartments) async {
    final box = await _getApartmentsBox();
    final metadataBox = await _getMetadataBox();

    // Добавляем timestamp к каждой квартире
    final apartmentsWithTimestamp =
        apartments.map((apt) {
          return apt.copyWith(cachedAt: DateTime.now());
        }).toList();

    // Очищаем старый кэш
    await box.clear();

    // Сохраняем только валидные квартиры
    int cachedCount = 0;
    for (var apartment in apartmentsWithTimestamp) {
      if (apartment.isValid()) {
        try {
          await box.put(apartment.id, apartment.toJson());
          cachedCount++;
        } catch (e) {
          print('⚠️ Failed to cache apartment ${apartment.id}: $e');
        }
      } else {
        print('⚠️ Skipping invalid apartment ${apartment.id}');
      }
    }

    // Сохраняем время последнего обновления
    await metadataBox.put(
      'last_cache_update',
      DateTime.now().toIso8601String(),
    );

    print('💾 Cached $cachedCount valid apartments');
  }

  /// Сохранить одну квартиру в кэш
  Future<void> cacheApartment(Apartment apartment) async {
    if (!apartment.isValid()) {
      print('⚠️ Cannot cache invalid apartment ${apartment.id}');
      return;
    }

    final box = await _getApartmentsBox();
    final apartmentWithTimestamp = apartment.copyWith(cachedAt: DateTime.now());

    try {
      await box.put(apartment.id, apartmentWithTimestamp.toJson());
      print('💾 Cached apartment #${apartment.id}');
    } catch (e) {
      print('⚠️ Failed to cache apartment ${apartment.id}: $e');
    }
  }

  /// Получить все квартиры из кэша (с фильтрацией битых данных)
  Future<List<Apartment>> getCachedApartments() async {
    final box = await _getApartmentsBox();
    final apartments = <Apartment>[];

    for (var json in box.values) {
      try {
        final apartment = Apartment.fromJson(Map<String, dynamic>.from(json));

        // ✅ Фильтруем невалидные объекты
        if (apartment.isValid()) {
          apartments.add(apartment);
        } else {
          print('⚠️ Skipping invalid apartment from cache: ${apartment.id}');
        }
      } catch (e) {
        print('⚠️ Failed to parse apartment from cache: $e');
        // Пропускаем битые данные
        continue;
      }
    }

    print('📂 Retrieved ${apartments.length} valid apartments from cache');
    return apartments;
  }

  /// Получить квартиру по ID из кэша
  Future<Apartment?> getCachedApartmentById(int id) async {
    final box = await _getApartmentsBox();
    final json = box.get(id);

    if (json != null) {
      try {
        final apartment = Apartment.fromJson(Map<String, dynamic>.from(json));

        if (apartment.isValid()) {
          print('📂 Retrieved apartment #$id from cache');
          return apartment;
        } else {
          print('⚠️ Apartment #$id is invalid');
          return null;
        }
      } catch (e) {
        print('⚠️ Failed to parse apartment #$id: $e');
        return null;
      }
    }
    return null;
  }

  /// Проверить, валиден ли кэш
  Future<bool> isCacheValid() async {
    try {
      final metadataBox = await _getMetadataBox();
      final box = await _getApartmentsBox();

      if (box.isEmpty) {
        print('❌ Cache is empty');
        return false;
      }

      final lastUpdateString = metadataBox.get('last_cache_update') as String?;
      if (lastUpdateString == null) {
        print('❌ No cache timestamp found');
        return false;
      }

      final lastUpdate = DateTime.parse(lastUpdateString);
      final difference = DateTime.now().difference(lastUpdate);
      final isValid = difference < _cacheValidDuration;

      if (isValid) {
        print(
          '✅ Cache is valid (age: ${difference.inHours}h ${difference.inMinutes % 60}m)',
        );
      } else {
        print('⏰ Cache expired (age: ${difference.inHours}h)');
      }

      return isValid;
    } catch (e) {
      print('❌ Error checking cache validity: $e');
      return false;
    }
  }

  /// Получить время последнего обновления кэша
  Future<DateTime?> getLastCacheUpdate() async {
    try {
      final metadataBox = await _getMetadataBox();
      final lastUpdateString = metadataBox.get('last_cache_update') as String?;
      if (lastUpdateString != null) {
        return DateTime.parse(lastUpdateString);
      }
    } catch (e) {
      print('❌ Error getting last cache update: $e');
    }
    return null;
  }

  /// Очистить кэш
  Future<void> clearCache() async {
    final box = await _getApartmentsBox();
    final metadataBox = await _getMetadataBox();
    await box.clear();
    await metadataBox.delete('last_cache_update');
    print('🗑️ Cache cleared');
  }

  /// Получить размер кэша
  Future<int> getCacheSize() async {
    final box = await _getApartmentsBox();
    return box.length;
  }
}
