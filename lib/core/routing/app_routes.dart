// lib/core/routing/app_routes.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:test_task/auth_guard.dart';
import 'package:test_task/booking_history_screen.dart';
import 'package:test_task/data/models/apartment.dart';
import 'package:test_task/data/models/excursion_model.dart';
import 'package:test_task/data/repositories/cars_repository.dart';
import 'package:test_task/data/repositories/motorcycle_repository.dart';
import 'package:test_task/data/repositories/vespa_repository.dart';
import 'package:test_task/presentation/apartment_detail_screen.dart';
import 'package:test_task/presentation/apartments_list_screen.dart';
import 'package:test_task/presentation/bookmarks.dart';
import 'package:test_task/presentation/chat_screen.dart';
import 'package:test_task/presentation/circular_menu_screen.dart';
import 'package:test_task/presentation/excursion_detail_screen.dart';
import 'package:test_task/presentation/excursions_list.dart';
import 'package:test_task/presentation/main_menu_screen.dart';
import 'package:test_task/presentation/profile_screen.dart';
import 'package:test_task/presentation/sign_up_screen.dart';
import 'package:test_task/presentation/splash_screen.dart';
import 'package:test_task/presentation/vehicle_details_screen.dart';

// =============================================
// FADE TRANSITION PAGE
// =============================================

/// Кастомная страница с fade-анимацией
class FadeTransitionPage<T> extends CustomTransitionPage<T> {
  FadeTransitionPage({
    required super.child,
    super.key,
    String? name,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) : super(
         name: name,
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: CurvedAnimation(parent: animation, curve: curve),
             child: child,
           );
         },
       );
}

/// Fade + Scale анимация (более эффектная)
class FadeScaleTransitionPage<T> extends CustomTransitionPage<T> {
  FadeScaleTransitionPage({
    required super.child,
    super.key,
    String? name,
    Duration duration = const Duration(milliseconds: 350),
    Duration reverseDuration = const Duration(milliseconds: 300),
  }) : super(
         name: name,
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           return FadeTransition(
             opacity: curvedAnimation,
             child: ScaleTransition(
               scale: Tween<double>(
                 begin: 0.95,
                 end: 1.0,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

/// Slide + Fade анимация (как в iOS)
class SlideUpFadeTransitionPage<T> extends CustomTransitionPage<T> {
  SlideUpFadeTransitionPage({
    required super.child,
    super.key,
    String? name,
    Duration duration = const Duration(milliseconds: 350),
  }) : super(
         name: name,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           return SlideTransition(
             position: Tween<Offset>(
               begin: const Offset(0, 0.05),
               end: Offset.zero,
             ).animate(curvedAnimation),
             child: FadeTransition(opacity: curvedAnimation, child: child),
           );
         },
       );
}

// =============================================
// APP ROUTER
// =============================================

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) => authRedirect(context, state),

    routes: [
      // Splash
      GoRoute(
        path: '/',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: const SplashScreen(),
            ),
      ),

      // Home
      GoRoute(
        path: '/home',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: const MainMenuScreen(),
            ),
        routes: [
          // Main Menu (круговое меню)
          GoRoute(
            path: 'main-menu',
            pageBuilder:
                (context, state) => FadeScaleTransitionPage(
                  key: state.pageKey,
                  child: const CircularMenuScreen(),
                ),
            routes: [
              // Apartments List
              GoRoute(
                path: 'apartments-list',
                pageBuilder:
                    (context, state) => SlideUpFadeTransitionPage(
                      key: state.pageKey,
                      child: ApartmentsListScreen(),
                    ),
                routes: [
                  // Apartment Detail
                  GoRoute(
                    path: 'apartment-detail',
                    pageBuilder: (context, state) {
                      final apartment = state.extra as Apartment;
                      return SlideUpFadeTransitionPage(
                        key: state.pageKey,
                        child: ApartmentDetailScreen(apartment: apartment),
                      );
                    },
                  ),
                ],
              ),

              // Vehicles - Cars
              GoRoute(
                path: 'vehicle-details-cars',
                pageBuilder: (context, state) {
                  final carRepository = context.read<CarRepository>();
                  return SlideUpFadeTransitionPage(
                    key: state.pageKey,
                    child: VehicleDetailsScreen(
                      vehicleRepository: carRepository,
                      label: "automobiles",
                    ),
                  );
                },
              ),

              // Vehicles - Motorcycles
              GoRoute(
                path: 'vehicle-details-motorcycles',
                pageBuilder: (context, state) {
                  final motorcycleRepository =
                      context.read<MotorcycleRepository>();
                  return SlideUpFadeTransitionPage(
                    key: state.pageKey,
                    child: VehicleDetailsScreen(
                      vehicleRepository: motorcycleRepository,
                      label: "motorcycles",
                    ),
                  );
                },
              ),

              // Vehicles - Vespa
              GoRoute(
                path: 'vehicle-details-vespa',
                pageBuilder: (context, state) {
                  final vespaRepository = context.read<VespaRepository>();
                  return SlideUpFadeTransitionPage(
                    key: state.pageKey,
                    child: VehicleDetailsScreen(
                      vehicleRepository: vespaRepository,
                      label: "vespa bikes",
                    ),
                  );
                },
              ),

              // Excursions List
              GoRoute(
                path: 'excursions-list',
                pageBuilder:
                    (context, state) => SlideUpFadeTransitionPage(
                      key: state.pageKey,
                      child: ExcursionsList(),
                    ),
                routes: [
                  // Excursion Detail
                  GoRoute(
                    path: 'excursion-detail',
                    pageBuilder: (context, state) {
                      final excursion = state.extra as Excursion;
                      return SlideUpFadeTransitionPage(
                        key: state.pageKey,
                        child: ExcursionDetailScreen(excursion: excursion),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // =============================================
      // AUTH ROUTES
      // =============================================
      GoRoute(
        path: '/sign-up',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: const SignUpScreen(),
            ),
      ),

      // =============================================
      // BOOKMARKS
      // =============================================
      GoRoute(
        path: '/bookmarks',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: BookmarksScreen(),
            ),
      ),

      // =============================================
      // PROTECTED ROUTES
      // =============================================
      GoRoute(
        path: '/profile',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: AuthGuard(child: ProfileScreen()),
            ),
      ),
      GoRoute(
        path: '/booking-history',
        builder: (context, state) => const BookingHistoryScreen(),
      ),

      GoRoute(
        path: '/chat',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: AuthGuard(child: ChatScreen()),
            ),
      ),
    ],

    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Ошибка')),
          body: const Center(child: Text('Не удалось загрузить страницу')),
        ),
  );

  static List<String> getAllRoutes() {
    return [
      '/home/main-menu/apartments-list',
      '/home/main-menu/vehicle-details-cars',
      '/home/main-menu/vehicle-details-motorcycles',
      '/home/main-menu/vehicle-details-vespa',
      '/home/main-menu/vehicle-details-vespa',
      '/home/main-menu/excursions-list',
    ];
  }
}
