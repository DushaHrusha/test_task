import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_task/bloc/cubits/apartments_cubit.dart';
import 'package:test_task/bloc/state/apartments_state.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/grey_line.dart';

import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/core/constants/second_card.dart';
import 'package:test_task/data/models/card_data.dart';

class ApartmentsListScreen extends StatefulWidget {
  const ApartmentsListScreen({super.key});

  @override
  createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen>
    with SingleTickerProviderStateMixin {
  final Map<int, int> ratings = {};

  late AnimationController _animationController;
  late Animation<double> _appBarOpacityAnimation;
  late Animation<Offset> _bottomBarSlideAnimation;
  late Animation<double> _cardsOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _appBarOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );
    _cardsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 0.8, curve: Curves.easeInOut),
      ),
    );
    _bottomBarSlideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 0.7, curve: Curves.easeOutQuad),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseColors.background,
      body: BlocBuilder<ApartmentCubit, ApartmentsState>(
        builder: (context, state) {
          // Обработка состояния загрузки
          if (state is ApartmentsLoading) {
            return Center(
              child: CircularProgressIndicator(color: BaseColors.accent),
            );
          }
          // Обработка состояния с данными
          // В ApartmentsListScreen
          else if (state is ApartmentsLoaded) {
            return CustomBackgroundWithGradient(
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _appBarOpacityAnimation,
                    child: CustomAppBar(label: "apartments"),
                  ),
                  FadeTransition(
                    opacity: _appBarOpacityAnimation,
                    child: GreyLine(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await context
                            .read<ApartmentCubit>()
                            .refreshApartments();
                      },
                      color: BaseColors.accent,
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 32,
                        ),
                        itemCount: state.apartments.length,
                        itemBuilder: (context, index) {
                          final apartment = state.apartments[index];
                          return FadeTransition(
                            opacity: _cardsOpacityAnimation,
                            child: GestureDetector(
                              onTap: () {
                                context.go(
                                  '/home/main-menu/apartments-list/apartment-detail',
                                  extra: apartment,
                                );
                              },
                              child: SecondCard(
                                index: index,
                                data: apartment,
                                context: context,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: BaseColors.accent,
                                  fontSize: 21,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          // Обработка состояния ошибки
          if (state is ApartmentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading apartments',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ApartmentCubit>().forceLoadFromServer();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Начальное состояние (на всякий случай)
          return Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: SlideTransition(
        position: _bottomBarSlideAnimation,
        child: BottomBar(currentScreen: widget),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SlideTransition(
        position: _bottomBarSlideAnimation,
        child: Container(
          margin: EdgeInsets.only(bottom: 30),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: SvgPicture.asset(
                  "assets/file/sliders.svg",
                  color: BaseColors.accent,
                  height: 24,
                ),
                onPressed: () => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
