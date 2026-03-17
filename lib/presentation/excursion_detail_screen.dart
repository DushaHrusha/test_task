import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:test_task/api_client.dart';
import 'package:test_task/bloc/cubits/bookmarks_cubit.dart';
import 'package:test_task/data/models/bookmark.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/data/models/card_data.dart';
import 'package:test_task/presentation/apartment_detail_screen.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/core/constants/custom_text_field_with_gradient_button.dart';
import 'package:test_task/data/models/excursion_model.dart';
import 'package:test_task/presentation/excursion_booking_service.dart';

// bloc/cubits/excursion_booking_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

// ===== States =====

abstract class ExcursionBookingState {}

class ExcursionBookingInitial extends ExcursionBookingState {}

class ExcursionBookingLoading extends ExcursionBookingState {}

class ExcursionBookingSuccess extends ExcursionBookingState {
  final Map<String, dynamic> booking;
  ExcursionBookingSuccess(this.booking);
}

class ExcursionBookingError extends ExcursionBookingState {
  final String message;
  ExcursionBookingError(this.message);
}

// ===== Cubit =====

class ExcursionBookingCubit extends Cubit<ExcursionBookingState> {
  final ExcursionBookingRepository _repository;

  ExcursionBookingCubit(this._repository) : super(ExcursionBookingInitial());

  Future<void> createBooking({
    required int excursionId,
    required DateTime bookingDate,
    required int adults,
    required int children,
    String currency = 'EUR',
    String? notes,
  }) async {
    emit(ExcursionBookingLoading());

    try {
      print('🎯 Creating excursion booking...');
      print('  Excursion ID: $excursionId');
      print('  Date: ${bookingDate.toString().split(' ')[0]}');
      print('  Adults: $adults, Children: $children');
      // ✅ ПРОВЕРЯЕМ ТОКЕН ПЕРЕД ЗАПРОСОМ

      print('\n📤 API Request: POST /excursion-bookings');
      final booking = await _repository.createBooking(
        excursionId: excursionId,
        bookingDate: bookingDate,
        adults: adults,
        children: children,
        currency: currency,
        notes: notes,
      );

      print('✅ Booking created successfully');
      emit(ExcursionBookingSuccess(booking));
    } catch (e) {
      print('❌ Booking failed: $e');

      // ✅ Проверяем тип ошибки
      String errorMessage = 'Failed to create booking';

      if (e.toString().contains('No internet connection') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Please connect to the internet to complete booking';
      } else {
        errorMessage = e.toString();
      }

      // ❌ Убираем rethrow! Просто эмитим ошибку
      emit(ExcursionBookingError(errorMessage));
    }
  }

  void reset() {
    emit(ExcursionBookingInitial());
  }
}

// data/repositories/excursion_booking_repository.dart

abstract class ExcursionBookingRepository {
  Future<Map<String, dynamic>> createBooking({
    required int excursionId,
    required DateTime bookingDate,
    required int adults,
    required int children,
    required String currency,
    String? notes,
  });

  Future<List<String>> getBookedDates(int excursionId);
}

class ExcursionBookingRepositoryImpl implements ExcursionBookingRepository {
  final ApiClient _apiClient;

  ExcursionBookingRepositoryImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> createBooking({
    required int excursionId,
    required DateTime bookingDate,
    required int adults,
    required int children,
    required String currency,
    String? notes,
  }) async {
    try {
      print('\n📤 API Request: POST /excursion-bookings');

      final requestData = {
        'excursion_id': excursionId,
        'booking_date': bookingDate.toIso8601String().split('T')[0],
        'adults': adults,
        'children': children,
        'currency': currency,
        if (notes != null) 'notes': notes,
      };

      print('📦 Request data: $requestData');

      final response = await _apiClient.post(
        '/excursion-bookings',
        data: requestData,
      );

      print('📥 Response: ${response.data}');

      if (response.data['success'] == true) {
        return response.data['data']['booking'] as Map<String, dynamic>;
      }

      throw Exception('Booking failed: ${response.data['message']}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.response?.data}');

      if (e.response?.statusCode == 409) {
        throw Exception('This date is already fully booked');
      }

      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception('Validation error: $errors');
      }

      throw Exception('Failed to create booking: ${e.message}');
    }
  }

  @override
  Future<List<String>> getBookedDates(int excursionId) async {
    try {
      final response = await _apiClient.get(
        '/v1/excursions/$excursionId/booked-dates',
      );

      if (response.data['success'] == true) {
        final List<dynamic> dates = response.data['data']['booked_dates'];
        return dates.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching booked dates: $e');
      return [];
    }
  }
}

class ExcursionDetailScreen extends StatefulWidget {
  final Excursion excursion;

  const ExcursionDetailScreen({super.key, required this.excursion});

  @override
  createState() => _ExcursionDetailScreenState();
}

class _ExcursionDetailScreenState extends State<ExcursionDetailScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late int displayedIconsCount;
  int _currentPage = 0;
  late List<IconData> icons;
  bool showAllIcons = false;
  late final Excursion _excursion;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _appBarOpacityAnimation;
  late Animation<Offset> _bottomBarSlideAnimation;
  late Animation<double> _cardsOpacityAnimation;
  int _currentPage1 = 0;

  @override
  void initState() {
    super.initState();
    _excursion = widget.excursion;
    icons = _excursion.iconDataList;
    displayedIconsCount = showAllIcons ? icons.length : 5;
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });

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
        curve: Interval(0.5, 1, curve: Curves.easeInOut),
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
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentPage == index
                    ? BaseColors.accent
                    : BaseColors.background,
          ),
        );
      }),
    );
  }

  void _scrollRight() {
    setState(() {
      if (_currentPage1 < icons.length - 5) {
        _currentPage1++;
        _scrollController.animateTo(
          _currentPage1 * 80.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _scrollLeft() {
    setState(() {
      if (_currentPage1 > 0) {
        _currentPage1--;
        _scrollController.animateTo(
          _currentPage1 * 80.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomBackgroundWithGradient(
        child: Column(
          children: [
            FadeTransition(
              opacity: _appBarOpacityAnimation,
              child: CustomAppBar(label: "excursion info"),
            ),
            FadeTransition(opacity: _appBarOpacityAnimation, child: GreyLine()),
            SizedBox(height: 40),
            Expanded(
              child: FadeTransition(
                opacity: _cardsOpacityAnimation,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.all(
                                Radius.circular(context.adaptiveSize(32)),
                              ),
                              child: SizedBox(
                                height: context.adaptiveSize(180),
                                width: MediaQuery.of(context).size.width,
                                child: PageView.builder(
                                  controller: _pageController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _excursion.imageUrl.length,
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: _excursion.imageUrl[index],
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) =>
                                              CircularProgressIndicator(),
                                      errorWidget:
                                          (context, url, error) =>
                                              Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              right: context.adaptiveSize(24),
                              top: context.adaptiveSize(24),
                              child:
                                  BlocBuilder<BookmarksCubit, List<Bookmark>>(
                                    builder: (context, bookmarks) {
                                      final isBookmarked = context
                                          .read<BookmarksCubit>()
                                          .isBookmarked(_excursion as CardData);
                                      return GestureDetector(
                                        onTap: () {
                                          context
                                              .read<BookmarksCubit>()
                                              .toggleBookmark(
                                                _excursion as CardData,
                                              );
                                        },
                                        child: Container(
                                          height: context.adaptiveSize(56),
                                          width: context.adaptiveSize(56),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                context.adaptiveSize(16),
                                              ),
                                            ),
                                            shape: BoxShape.rectangle,
                                            color: Color.fromARGB(
                                              87,
                                              255,
                                              255,
                                              255,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                context.adaptiveSize(16),
                                              ),
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 5.0,
                                                sigmaY: 5.0,
                                              ),
                                              child: Icon(
                                                isBookmarked
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_outline,
                                                color:
                                                    isBookmarked
                                                        ? BaseColors.accent
                                                        : Color.fromARGB(
                                                          255,
                                                          251,
                                                          251,
                                                          253,
                                                        ),
                                                size: context.adaptiveSize(25),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                            Positioned(
                              bottom: context.adaptiveSize(16),
                              left: 0,
                              right: 0,
                              child: _buildIndicator(
                                _excursion.imageUrl.length,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.adaptiveSize(12)),
                        Text(
                          _excursion.title,
                          softWrap: true,
                          style: context.adaptiveTextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: BaseColors.text,
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(16)),
                        Text(
                          _excursion.description,
                          style: context.adaptiveTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 130, 130, 130),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.adaptiveSize(24)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Duration:",
                              style: context.adaptiveTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: BaseColors.text,
                              ),
                            ),
                            Text(
                              "${_excursion.duration} hours",
                              style: context.adaptiveTextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: BaseColors.accent,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: context.adaptiveSize(100)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Starting time:",
                              style: context.adaptiveTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: BaseColors.text,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'HH:mm',
                              ).format(_excursion.startingTime),
                              style: context.adaptiveTextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: BaseColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: context.adaptiveSize(32)),
                    Row(
                      children: [
                        if (_currentPage1 > 0)
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios,
                              size: context.adaptiveSize(20),
                            ),
                            onPressed: _scrollLeft,
                          ),
                        Expanded(
                          child: SizedBox(
                            height: context.adaptiveSize(48),
                            child: ListView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: _excursion.iconServices.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(
                                    right: context.adaptiveSize(12),
                                  ),
                                  height: context.adaptiveSize(48),
                                  width: context.adaptiveSize(46),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 224, 224, 224),
                                      width: 1,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: Color.fromARGB(0, 1, 1, 1),
                                    child: Icon(
                                      icons[index],
                                      color: BaseColors.text,
                                      size: context.adaptiveSize(20),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (_currentPage1 < icons.length - 5)
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              size: context.adaptiveSize(14),
                              color: Color.fromARGB(255, 189, 189, 189),
                            ),
                            onPressed: _scrollRight,
                          ),
                      ],
                    ),
                    SizedBox(height: 40),
                    GreyLine(),
                    SizedBox(height: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer:',
                          style: context.adaptiveTextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: BaseColors.text,
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(8.0)),
                        Text(
                          _excursion.transfer.join(' — '),
                          style: context.adaptiveTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 130, 130, 130),
                          ),
                        ),

                        SizedBox(height: context.adaptiveSize(32.0)),
                        Text(
                          'Sights:',
                          style: context.adaptiveTextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: BaseColors.text,
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(8.0)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            _excursion.sights.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: context.adaptiveSize(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: BaseColors.accent,
                                    size: context.adaptiveSize(16),
                                  ),
                                  SizedBox(width: context.adaptiveSize(8.0)),
                                  Text(
                                    _excursion.sights[index],
                                    style: context.adaptiveTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color.fromARGB(255, 130, 130, 130),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(32.0)),
                        Text(
                          'Not included:',
                          style: context.adaptiveTextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: BaseColors.text,
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(8.0)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            _excursion.notIncluded.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: context.adaptiveSize(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.clear,
                                    color: BaseColors.text,
                                    size: context.adaptiveSize(16),
                                  ),
                                  SizedBox(width: context.adaptiveSize(8.0)),
                                  Text(
                                    _excursion.notIncluded[index],
                                    style: context.adaptiveTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color.fromARGB(255, 130, 130, 130),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(32.0)),
                        Text(
                          'Take with you:',
                          style: context.adaptiveTextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: BaseColors.text,
                          ),
                        ),
                        SizedBox(height: context.adaptiveSize(8.0)),
                        Text(
                          _excursion.takeWithYou,
                          style: context.adaptiveTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 130, 130, 130),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.adaptiveSize(40)),
                    GreyLine(),
                    SizedBox(height: context.adaptiveSize(24)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _excursion.rating.toString(),
                              style: context.adaptiveTextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: BaseColors.accent,
                              ),
                            ),
                            SizedBox(width: context.adaptiveSize(6)),
                            StarRating(rating: _excursion.rating),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${_excursion.numberReviews} guest reviews",
                              style: context.adaptiveTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color.fromARGB(255, 130, 130, 130),
                              ),
                            ),
                            SizedBox(width: context.adaptiveSize(12)),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: context.adaptiveSize(14),
                              color: Color.fromARGB(255, 189, 189, 189),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: context.adaptiveSize(27)),
                    GreyLine(),
                    SizedBox(height: context.adaptiveSize(40)),
                    // В методе build, замените CustomTextFieldWithGradientButton на:
                    GestureDetector(
                      onTap: () => _bookExcursion(context, _excursion),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [BaseColors.accent, BaseColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "${_excursion.price.cleanFormat()} € / person - Book Now",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SlideTransition(
        position: _bottomBarSlideAnimation,
        child: BottomBar(currentScreen: widget),
      ),
    );
  }
}

// Замени метод _bookExcursion на:

Future<void> _bookExcursion(BuildContext context, Excursion excursion) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder:
        (context) => ExcursionBookingDialog(
          excursionId: excursion.id,
          pricePerPerson: excursion.price,
        ),
  );

  if (result != null) {
    // ✅ Используем ExcursionBookingCubit
    await context.read<ExcursionBookingCubit>().createBooking(
      excursionId: excursion.id,
      bookingDate: result['date'],
      adults: result['adults'],
      children: result['children'],
      currency: 'EUR',
      notes: 'Booked from mobile app',
    );

    // Слушаем результат
    final state = context.read<ExcursionBookingCubit>().state;

    if (state is ExcursionBookingSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excursion booked successfully! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is ExcursionBookingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

extension CleanDoubleFormat on double {
  String cleanFormat() {
    return toStringAsFixed(2).replaceAll('.00', '');
  }
}

class ExcursionBookingDialog extends StatefulWidget {
  final int excursionId;
  final double pricePerPerson;

  const ExcursionBookingDialog({
    super.key,
    required this.excursionId,
    required this.pricePerPerson,
  });

  @override
  State<ExcursionBookingDialog> createState() => _ExcursionBookingDialogState();
}

class _ExcursionBookingDialogState extends State<ExcursionBookingDialog> {
  DateTime? _selectedDate;
  int _adults = 1;
  int _children = 0;

  double get _totalPrice {
    return widget.pricePerPerson * (_adults + _children);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.all(0),
      contentPadding: EdgeInsets.all(0),
      backgroundColor: Colors.transparent,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 314,
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close, size: 32, color: BaseColors.background),
            ),
          ),
          Container(
            width: 330,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              color: BaseColors.background,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Book Excursion',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 109, 109, 109),
                    ),
                  ),
                  SizedBox(height: 24),
                  GreyLine(),
                  SizedBox(height: 24),

                  // Date Selection
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate != null
                                ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_selectedDate!)
                                : 'Select Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Adults Counter
                  _buildCounter('Adults', _adults, (value) {
                    setState(() => _adults = value);
                  }),

                  SizedBox(height: 16),

                  // Children Counter
                  _buildCounter('Children', _children, (value) {
                    setState(() => _children = value);
                  }),

                  SizedBox(height: 24),
                  GreyLine(),
                  SizedBox(height: 24),

                  // Total Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BaseColors.accent,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Book Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [BaseColors.accent, BaseColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            (_selectedDate != null && (_adults + _children) > 0)
                                ? () {
                                  Navigator.pop(context, {
                                    'date': _selectedDate!,
                                    'adults': _adults,
                                    'children': _children,
                                  });
                                }
                                : null,
                        borderRadius: BorderRadius.circular(25),
                        child: Center(
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: Icon(Icons.remove_circle_outline),
              color: BaseColors.accent,
            ),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: Icon(Icons.add_circle_outline),
              color: BaseColors.accent,
            ),
          ],
        ),
      ],
    );
  }
}
