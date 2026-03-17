// data/datasources/excursions_local_data_source.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:test_task/data/models/excursion_model.dart';

class ExcursionsLocalDataSource {
  static const String _boxName = 'excursions_cache';
  static const String _metadataBoxName = 'excursions_cache_metadata';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // ✅ Версия кэша - увеличь до 3 чтобы очистить старые данные
  static const int _cacheVersion = 3;
  static const String _versionKey = 'cache_version';

  /// Получить бокс для экскурсий
  Future<Box<Map>> _getExcursionsBox() async {
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
          '⚠️ Excursions cache version mismatch (current: $currentVersion, required: $_cacheVersion)',
        );
        print('🗑️ Clearing excursions cache...');
        await box.clear();
        await metadataBox.put(_versionKey, _cacheVersion);
        await metadataBox.delete('last_cache_update');
        print(
          '✅ Excursions cache cleared and version updated to $_cacheVersion',
        );
      }
    } catch (e) {
      print('❌ Error checking excursions cache version: $e');
    }
  }

  /// Сохранить список экскурсий в кэш
  Future<void> cacheExcursions(List<Excursion> excursions) async {
    final box = await _getExcursionsBox();
    final metadataBox = await _getMetadataBox();

    // Добавляем timestamp к каждой экскурсии
    final excursionsWithTimestamp =
        excursions.map((exc) {
          return exc.copyWith(cachedAt: DateTime.now());
        }).toList();

    // Очищаем старый кэш
    await box.clear();

    // Сохраняем только валидные экскурсии
    int cachedCount = 0;
    for (var excursion in excursionsWithTimestamp) {
      if (excursion.isValid()) {
        try {
          await box.put(excursion.id, excursion.toJson());
          cachedCount++;
        } catch (e) {
          print('⚠️ Failed to cache excursion ${excursion.id}: $e');
        }
      } else {
        print('⚠️ Skipping invalid excursion ${excursion.id}');
      }
    }

    // Сохраняем время последнего обновления
    await metadataBox.put(
      'last_cache_update',
      DateTime.now().toIso8601String(),
    );

    print('💾 Cached $cachedCount valid excursions');
  }

  /// Сохранить одну экскурсию в кэш
  Future<void> cacheExcursion(Excursion excursion) async {
    if (!excursion.isValid()) {
      print('⚠️ Cannot cache invalid excursion ${excursion.id}');
      return;
    }

    final box = await _getExcursionsBox();
    final excursionWithTimestamp = excursion.copyWith(cachedAt: DateTime.now());

    try {
      await box.put(excursion.id, excursionWithTimestamp.toJson());
      print('💾 Cached excursion #${excursion.id}');
    } catch (e) {
      print('⚠️ Failed to cache excursion ${excursion.id}: $e');
    }
  }

  /// Получить все экскурсии из кэша (с фильтрацией битых данных)
  Future<List<Excursion>> getCachedExcursions() async {
    final box = await _getExcursionsBox();
    final excursions = <Excursion>[];

    for (var json in box.values) {
      try {
        final excursion = Excursion.fromJson(Map<String, dynamic>.from(json));

        // ✅ Фильтруем невалидные объекты
        if (excursion.isValid()) {
          excursions.add(excursion);
        } else {
          print('⚠️ Skipping invalid excursion from cache: ${excursion.id}');
        }
      } catch (e) {
        print('⚠️ Failed to parse excursion from cache: $e');
        // Пропускаем битые данные
        continue;
      }
    }

    print('📂 Retrieved ${excursions.length} valid excursions from cache');
    return excursions;
  }

  /// Получить экскурсию по ID из кэша
  Future<Excursion?> getCachedExcursionById(int id) async {
    final box = await _getExcursionsBox();
    final json = box.get(id);

    if (json != null) {
      try {
        final excursion = Excursion.fromJson(Map<String, dynamic>.from(json));

        if (excursion.isValid()) {
          print('📂 Retrieved excursion #$id from cache');
          return excursion;
        } else {
          print('⚠️ Excursion #$id is invalid');
          return null;
        }
      } catch (e) {
        print('⚠️ Failed to parse excursion #$id: $e');
        return null;
      }
    }
    return null;
  }

  /// Проверить, валиден ли кэш
  Future<bool> isCacheValid() async {
    try {
      final metadataBox = await _getMetadataBox();
      final box = await _getExcursionsBox();

      if (box.isEmpty) {
        print('❌ Excursions cache is empty');
        return false;
      }

      final lastUpdateString = metadataBox.get('last_cache_update') as String?;
      if (lastUpdateString == null) {
        print('❌ No excursions cache timestamp found');
        return false;
      }

      final lastUpdate = DateTime.parse(lastUpdateString);
      final difference = DateTime.now().difference(lastUpdate);
      final isValid = difference < _cacheValidDuration;

      if (isValid) {
        print(
          '✅ Excursions cache is valid (age: ${difference.inHours}h ${difference.inMinutes % 60}m)',
        );
      } else {
        print('⏰ Excursions cache expired (age: ${difference.inHours}h)');
      }

      return isValid;
    } catch (e) {
      print('❌ Error checking excursions cache validity: $e');
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
      print('❌ Error getting last excursions cache update: $e');
    }
    return null;
  }

  /// Очистить кэш
  Future<void> clearCache() async {
    final box = await _getExcursionsBox();
    final metadataBox = await _getMetadataBox();
    await box.clear();
    await metadataBox.delete('last_cache_update');
    print('🗑️ Excursions cache cleared');
  }

  /// Получить размер кэша
  Future<int> getCacheSize() async {
    final box = await _getExcursionsBox();
    return box.length;
  }
}
