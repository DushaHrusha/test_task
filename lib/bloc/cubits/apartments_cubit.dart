import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_task/bloc/state/apartments_state.dart';
import 'package:test_task/data/repositories/apartments_repository.dart';

class ApartmentCubit extends Cubit<ApartmentsState> {
  final ApartmentsRepository apartmentsRepository;
  ApartmentCubit({required this.apartmentsRepository})
    : super(ApartmentsInitial()) {
    loadApartments();
  }
  Future<void> loadApartments({bool forceRefresh = false}) async {
    print(
      '🏠 ApartmentCubit: loadApartments started (forceRefresh: $forceRefresh)',
    );

    // Показываем loading только если это forceRefresh (pull-to-refresh)
    if (forceRefresh) {
      emit(ApartmentsLoading());
    }

    try {
      final apartments = await apartmentsRepository.getApartments(
        forceRefresh: forceRefresh,
      );

      print('🏠 ApartmentCubit: Loaded ${apartments.length} apartments');
      emit(ApartmentsLoaded(apartments));
    } catch (e) {
      print('🏠 ApartmentCubit: Error loading apartments: $e');

      // Если уже есть данные в state, оставляем их
      if (state is ApartmentsLoaded) {
        print('🏠 Keeping existing data after error');
      } else {
        emit(ApartmentsError(e.toString()));
      }
    }
  }

  /// Pull-to-refresh (с индикатором загрузки)
  Future<void> refreshApartments() async {
    print('🏠 ApartmentCubit: refreshApartments started');
    await loadApartments(forceRefresh: true);
  }

  /// Принудительная перезагрузка (для кнопки "Retry")
  Future<void> forceLoadFromServer() async {
    print('🏠 ApartmentCubit: forceLoadFromServer started');
    emit(ApartmentsLoading());
    await loadApartments(forceRefresh: true);
  }

  /// Очистить кэш и перезагрузить
  Future<void> clearCacheAndReload() async {
    print('🏠 ApartmentCubit: Clearing cache...');
    await apartmentsRepository.clearCache();
    print('🏠 ApartmentCubit: Cache cleared, reloading...');
    await loadApartments(forceRefresh: true);
  }

  /// Очистить кэш
  Future<void> clearCache() async {
    await apartmentsRepository.clearCache();
    await loadApartments(forceRefresh: true);
  }

  /// Получить информацию о кэше
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await apartmentsRepository.getCacheInfo();
  }
}
