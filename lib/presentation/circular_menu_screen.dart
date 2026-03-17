import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/core/routing/app_routes.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';

class CircularMenuScreen extends StatefulWidget {
  const CircularMenuScreen({super.key});

  @override
  createState() => _CircularMenuScreenState();
}

class _CircularMenuScreenState extends State<CircularMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late final List<String> _cachedPages;
  final List<String> _pages = AppRouter.getAllRoutes();

  final List<String> _labels = [
    'Apartment',
    'Auto',
    'Moto',
    'Bicycle',
    'Vespa',
    'Excursion',
    'What are you looking for?',
  ];
  final List<String> _svgIcons = [
    'assets/file/keys.svg',
    'assets/file/auto.svg',
    'assets/file/Moto.svg',
    'assets/file/Bicycle.svg',
    'assets/file/Vespa.svg',
    'assets/file/Excursion.svg',
  ];
  late AnimationController _stageController;
  late AnimationController _appBarController;
  late AnimationController _searchController;
  late AnimationController _circlesController;
  late AnimationController _bottomBarController;
  late AnimationController _animationTextController;
  late AnimationController _centerCirclesController;

  @override
  void initState() {
    super.initState();

    _cachedPages = _pages.map((page) => page).toList();

    _centerCirclesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _appBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _circlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    );

    _stageController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 0), () {
          _appBarController.forward().then((_) {
            _searchController.forward().then((_) {
              _circlesController.forward().then((_) {
                _controller.forward();
                _bottomBarController.forward();
                _animationTextController.forward();
                _centerCirclesController.forward();
              });
            });
          });
        });
      }
    });

    _stageController.forward();
  }

  @override
  void dispose() {
    _stageController.dispose();
    _appBarController.dispose();
    _searchController.dispose();
    _circlesController.dispose();
    _bottomBarController.dispose();
    _controller.dispose();
    _animationTextController.dispose();
    _centerCirclesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.shortestSide * 0.25;
    final center = Offset(size * 2, size * 2);
    final radius = size * 1.1;
    return Scaffold(
      backgroundColor: BaseColors.background,
      body: CustomBackgroundWithGradient(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _appBarController,
              builder: (context, child) {
                return Opacity(
                  opacity: _appBarController.value,
                  child: CustomAppBar(label: "trapani viaggio"),
                );
              },
            ),
            AnimatedBuilder(
              animation: _searchController,
              builder: (context, child) {
                return Opacity(
                  opacity: _searchController.value,
                  child: GreyLine(),
                );
              },
            ),
            AnimatedBuilder(
              animation: _searchController,
              builder: (context, child) {
                return Opacity(
                  opacity: _searchController.value,
                  child: Padding(
                    padding: context.adaptivePadding(
                      EdgeInsets.only(top: 48, left: 30, right: 30),
                    ),
                    child: Container(
                      height: context.adaptiveSize(40),
                      decoration: BoxDecoration(
                        color: BaseColors.background,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Color.fromRGBO(224, 224, 224, 1),
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          prefixIcon: Padding(
                            padding: context.adaptivePadding(
                              const EdgeInsets.only(left: 28, right: 6),
                            ),
                            child: Align(
                              widthFactor: 1.0,
                              heightFactor: 1.0,
                              child: SizedBox(
                                width: context.adaptiveSize(20),
                                height: context.adaptiveSize(20),
                                child: SvgPicture.asset(
                                  "assets/file/search.svg",
                                  color: BaseColors.primary,
                                ),
                              ),
                            ),
                          ),
                          hintText: 'What do you want to find in Trapani?',
                          hintStyle: TextStyle(
                            fontSize: context.adaptiveSize(14),
                            height: 1.0,
                            color: BaseColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 0,
                          ),
                          isDense: true,
                          isCollapsed: true,
                        ),
                        style: TextStyle(fontSize: 14, height: 1.0),
                        maxLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(
              width: size * 4,
              height: size * 5,
              child: Padding(
                padding: context.adaptivePadding(EdgeInsets.only(top: 45.0)),
                child: Stack(
                  children: List.generate(7, (index) {
                    final angle =
                        index == 6 ? 0.0 : (index * 60 - 90) * (pi / 180);
                    final offset =
                        index == 6
                            ? Offset(size * 2 - 4, size * 2 - 4)
                            : Offset(
                              center.dx + radius * cos(angle),
                              center.dy + radius * sin(angle),
                            );
                    return Positioned(
                      left: offset.dx - size / 2,
                      top: offset.dy - size / 2,
                      child:
                          index == 6
                              ? _buildCenterCircle(size + 8)
                              : ScaleTransition(
                                scale: Tween<double>(begin: 0, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _controller,
                                    curve: Interval(
                                      index * 0.1,
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                                child: _buildRegularCircle(size, index),
                              ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _bottomBarController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _bottomBarController,
                curve: Curves.easeOut,
              ),
            ),
            child: BottomBar(currentScreen: widget),
          );
        },
      ),
    );
  }

  Widget _buildRegularCircle(double size, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashFactory: InkRipple.splashFactory,
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () {
          context.go(_cachedPages[index]);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: BaseColors.backgroundCircles,
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _animationTextController,
            builder: (context, child) {
              final textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationTextController,
                  curve: Interval(
                    0.05 * index,
                    0.2 * (index),
                    curve: Curves.easeInOut,
                  ),
                ),
              );
              return Opacity(
                opacity: textOpacity.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      _svgIcons[index],
                      color: BaseColors.secondary,
                    ),
                    SizedBox(height: size * 0.03),
                    Text(
                      _labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size * 0.13,
                        color: BaseColors.secondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCircle(double size) {
    return AnimatedBuilder(
      animation: _centerCirclesController,
      builder: (context, child) {
        final textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _centerCirclesController,
            curve: Interval(0.7, 1, curve: Curves.linear),
          ),
        );
        return Opacity(
          opacity: textOpacity.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: DashedCirclePainter(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _labels[6],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size * 0.14,
                      color: BaseColors.accent,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = BaseColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
    double dashWidth = 5, dashSpace = 5, radius = size.width / 2;
    double startAngle = 0;
    while (startAngle < 2 * pi) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: radius,
        ),
        startAngle,
        dashWidth / radius,
        false,
        paint,
      );
      startAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
