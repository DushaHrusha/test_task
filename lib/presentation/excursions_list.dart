import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_task/bloc/cubits/apartments_cubit.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/bloc/cubits/excursion_cubit.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/bloc/state/excursion_state.dart';
import 'package:test_task/core/constants/first_card.dart';
import 'package:test_task/core/constants/second_card.dart';

class ExcursionsList extends StatefulWidget {
  const ExcursionsList({super.key});

  @override
  createState() => _ExcursionsListState();
}

class _ExcursionsListState extends State<ExcursionsList>
    with SingleTickerProviderStateMixin {
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
      body: BlocBuilder<ExcursionCubit, ExcursionState>(
        builder: (context, state) {
          if (state is ExcursionLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is ExcursionLoaded) {
            return CustomBackgroundWithGradient(
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _appBarOpacityAnimation,
                    child: CustomAppBar(label: "excursions list"),
                  ),
                  FadeTransition(
                    opacity: _appBarOpacityAnimation,
                    child: GreyLine(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await context
                            .read<ExcursionCubit>()
                            .refreshExcursions();
                      },
                      color: BaseColors.accent,
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 32,
                        ),
                        itemCount: state.excursions.length,
                        itemBuilder: (context, index) {
                          final excursion = state.excursions[index];
                          return FadeTransition(
                            opacity: _cardsOpacityAnimation,
                            child: GestureDetector(
                              onTap: () {
                                context.go(
                                  '/home/main-menu/excursions-list/excursion-detail',
                                  extra: excursion,
                                );
                              },
                              child:
                                  (index == 0)
                                      ? FirstCard(
                                        data: excursion,
                                        index: index,
                                        context: context,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: BaseColors.accent,
                                          fontSize: 21,
                                        ),
                                      )
                                      : SecondCard(
                                        data: excursion,
                                        context: context,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: BaseColors.accent,
                                          fontSize: 21,
                                        ),
                                        index: index,
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
          } else if (state is ExcursionError) {
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
                  // Text(
                  //   state. message,
                  //   style: TextStyle(color: Colors.grey),
                  //   textAlign: TextAlign.center,
                  // ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ExcursionCubit>().loadExcursions();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error loading excursions'));
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
