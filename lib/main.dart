import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test_task/api_client.dart';
import 'package:test_task/api_endpoints.dart';
import 'package:test_task/auth_cubit.dart';
import 'package:test_task/auth_guard.dart';
import 'package:test_task/bloc/cubits/bookmarks_cubit.dart';
import 'package:test_task/booking_service.dart';
import 'package:test_task/core/constants/vehicle_booking_service.dart';
import 'package:test_task/core/routing/app_routes.dart';
import 'package:test_task/core/theme/app_theme.dart';
import 'package:test_task/bloc/cubits/apartments_cubit.dart';
import 'package:test_task/bloc/cubits/chat_cubit.dart';
import 'package:test_task/bloc/cubits/excursion_cubit.dart';
import 'package:test_task/data/repositories/apartments_local_data_source.dart';
import 'package:test_task/data/repositories/apartments_repository.dart';
import 'package:test_task/data/repositories/cars_repository.dart';
import 'package:test_task/data/repositories/connectivity_service.dart';
import 'package:test_task/data/repositories/excursions_local_data_source.dart';
import 'package:test_task/data/repositories/excursions_repository.dart';
import 'package:test_task/data/repositories/motorcycle_repository.dart';
import 'package:test_task/data/repositories/vehicles_local_datasource.dart';
import 'package:test_task/data/repositories/vespa_repository.dart';
import 'package:test_task/presentation/booking_cubit.dart';
import 'package:test_task/presentation/dates_guests_screen.dart';
import 'package:test_task/presentation/excursion_booking_service.dart';
import 'package:test_task/presentation/excursion_detail_screen.dart';
import 'package:test_task/presentation/vehicle_details_screen.dart';
import 'package:test_task/unified_booking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // print('🗑️ [DEBUG] Clearing all cache...');
  // try {
  //   await Hive.deleteBoxFromDisk('apartments_cache');
  //   await Hive.deleteBoxFromDisk('excursions_cache');
  //   await Hive.deleteBoxFromDisk('cars_cache');
  //   await Hive.deleteBoxFromDisk('motorcycles_cache');
  //   await Hive.deleteBoxFromDisk('vespas_cache');
  //   await Hive.deleteBoxFromDisk('cache_metadata');
  //   await Hive.deleteBoxFromDisk('vehicles_cache_metadata');
  //   await Hive.deleteBoxFromDisk('excursions_cache_metadata');
  //   print('✅ [DEBUG] Cache cleared');
  // } catch (e) {
  //   print('⚠️ [DEBUG] Error clearing cache: $e');
  // }

  // ===== СОЗДАЁМ СИНГЛТОНЫ СЕРВИСОВ =====
  final token = TokenLocalDataSource();

  final apiClient = ApiClient(
    baseUrl: ApiEndpoints.baseUrl,
    tokenStorage: token,
  );
  final connectivityService = ConnectivityService();
  final bookingService = BookingService(apiClient);

  final vehicleBookingService = VehicleBookingService(apiClient); // ← Добавьте
  final unifiedBookingService = UnifiedBookingService(apiClient);
  final apartmentsLocalDataSource = ApartmentsLocalDataSource();
  final excursionsLocalDataSource = ExcursionsLocalDataSource();
  final vehiclesLocalDataSource = VehiclesLocalDataSource();
  final excursionBookingService = ExcursionBookingService(
    apiClient,
  ); // ← Добавьте
  // Repositories
  final BookingsRepository bookingsRepository = BookingsRepositoryImpl(
    apiClient,
  );
  final vehicleBookingsRepository = VehicleBookingRepositoryImpl(apiClient);
  final ExcursionBookingRepository excursionBookingsRepository =
      ExcursionBookingRepositoryImpl(apiClient);
  final authRepository = AuthRepositoryImpl(
    apiClient: apiClient,
    tokenStorage: token,
  );
  final apartmentsRepository = ApartmentsRepositoryImpl(
    apiClient: apiClient,
    localDataSource: apartmentsLocalDataSource,
    connectivityService: connectivityService,
  );

  final excursionsRepository = ExcursionsRepositoryImpl(
    apiClient: apiClient,
    localDataSource: excursionsLocalDataSource,
    connectivityService: connectivityService,
  );

  final carRepository = CarRepository(
    apiClient: apiClient,
    localDataSource: vehiclesLocalDataSource,
    connectivityService: connectivityService,
  );

  final motorcycleRepository = MotorcycleRepository(
    apiClient: apiClient,
    localDataSource: vehiclesLocalDataSource,
    connectivityService: connectivityService,
  );
  final vespaRepository = VespaRepository(
    apiClient: apiClient,
    localDataSource: vehiclesLocalDataSource,
    connectivityService: connectivityService,
  );

  authCubit = AuthCubit(authRepository: authRepository);
  await authCubit.initialize();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: bookingsRepository),
        RepositoryProvider.value(value: apartmentsRepository),
        RepositoryProvider.value(value: excursionsRepository),
        RepositoryProvider.value(value: carRepository),
        RepositoryProvider.value(value: motorcycleRepository),
        RepositoryProvider.value(value: vespaRepository),
        RepositoryProvider.value(value: connectivityService),
        RepositoryProvider.value(value: vehiclesLocalDataSource),
        RepositoryProvider.value(value: vehicleBookingService),
        RepositoryProvider.value(value: excursionBookingService),
        RepositoryProvider.value(value: unifiedBookingService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider(
            create: (context) => ApartmentBookingCubit(bookingsRepository),
          ),
          BlocProvider(
            create: (context) => UnifiedBookingCubit(unifiedBookingService),
          ),
          BlocProvider(
            create:
                (context) =>
                    ApartmentCubit(apartmentsRepository: apartmentsRepository),
          ),
          BlocProvider(create: (context) => ChatCubit()),
          BlocProvider(
            create:
                (context) =>
                    ExcursionCubit(excursionsRepository: excursionsRepository),
          ),
          BlocProvider(create: (context) => BookmarksCubit()),
          BlocProvider(
            create:
                (context) =>
                    ApartmentBookingCubit(context.read<BookingsRepository>()),
          ),
          BlocProvider(
            create:
                (context) => ExcursionBookingCubit(excursionBookingsRepository),
          ),
          BlocProvider(
            create: (context) => VehicleBookingCubit(vehicleBookingsRepository),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trapani Viaggio App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
