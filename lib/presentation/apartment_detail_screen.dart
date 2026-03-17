import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_task/bloc/cubits/bookmarks_cubit.dart';
import 'package:test_task/data/models/bookmark.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/core/constants/custom_text_field_with_gradient_button.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/data/models/apartment.dart';
import 'package:test_task/data/models/card_data.dart';
import 'package:test_task/presentation/booking_cubit.dart';
import 'package:test_task/presentation/dates_guests_screen.dart';
import 'package:provider/provider.dart';

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_task/bloc/cubits/bookmarks_cubit.dart';
import 'package:test_task/data/models/bookmark.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/core/constants/custom_text_field_with_gradient_button.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/data/models/apartment.dart';
import 'package:test_task/data/models/card_data.dart';
import 'package:test_task/presentation/dates_guests_screen.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final Apartment apartment;

  const ApartmentDetailScreen({super.key, required this.apartment});

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late int displayedIconsCount;
  int _currentPage = 0;
  late List<IconData> icons;
  bool showAllIcons = false;
  late final Apartment _apartment;
  final ScrollController _scrollController = ScrollController();
  int _currentPage1 = 0;
  late AnimationController _animationController;
  late Animation<double> _appBarOpacityAnimation;
  late Animation<Offset> _bottomBarSlideAnimation;
  late Animation<double> _cardsOpacityAnimation;

  // ✅ Переменные для хранения выбранных дат и гостей
  DateTime? selectedCheckIn;
  DateTime? selectedCheckOut;
  int selectedAdults = 2;
  int selectedChildren = 1;

  @override
  void initState() {
    super.initState();
    icons = widget.apartment.iconDataList;
    displayedIconsCount = showAllIcons ? icons.length : 5;
    _apartment = widget.apartment;

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
    _animationController.dispose();
    _scrollController.dispose();
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

  // ✅ Рассчитать общую стоимость
  double _calculateTotalPrice() {
    if (selectedCheckIn == null || selectedCheckOut == null) {
      return _apartment.price;
    }
    final nights = selectedCheckOut!.difference(selectedCheckIn!).inDays;
    return _apartment.price * nights;
  }

  // ✅ Обработка бронирования
  // ✅ Обработка бронирования БЕЗ try-catch (слушаем BlocListener)
  Future<void> _handleBooking() async {
    if (selectedCheckIn == null || selectedCheckOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select dates first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cubit = context.read<ApartmentBookingCubit>();

    // Показываем loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    // ✅ Проверяем доступность
    final isAvailable = await cubit.checkAvailability(
      apartmentId: _apartment.id,
      checkIn: selectedCheckIn!,
      checkOut: selectedCheckOut!,
    );

    if (!isAvailable) {
      Navigator.pop(context); // Закрываем loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sorry, these dates are already booked'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Создаем бронирование (ошибки обрабатываются в BlocListener)
    await cubit.createBooking(
      apartmentId: _apartment.id,
      checkIn: selectedCheckIn!,
      checkOut: selectedCheckOut!,
      adults: selectedAdults,
      children: selectedChildren,
    );

    // Закрываем loading
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();

    return BlocListener<ApartmentBookingCubit, ApartmentBookingState>(
      listener: (context, state) {
        if (state is ApartmentBookingSuccess) {
          // ✅ Успешное бронирование
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is ApartmentBookingError) {
          // ✅ Ошибка бронирования (ОСТАЁМСЯ НА ЭКРАНЕ!)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleBooking(),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: CustomBackgroundWithGradient(
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
              SizedBox(height: 16),
              Expanded(
                child: FadeTransition(
                  opacity: _cardsOpacityAnimation,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    children: [
                      // ✅ Панель с датами и количеством гостей
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => BlocProvider.value(
                                  value: context.read<ApartmentBookingCubit>(),
                                  child: DatesGuestsScreen(
                                    apartment: _apartment,
                                    onConfirm: (
                                      checkIn,
                                      checkOut,
                                      adults,
                                      children,
                                    ) {
                                      // ✅ Обновляем состояние
                                      setState(() {
                                        selectedCheckIn = checkIn;
                                        selectedCheckOut = checkOut;
                                        selectedAdults = adults;
                                        selectedChildren = children;
                                      });
                                    },
                                  ),
                                ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              context.adaptiveSize(16),
                            ),
                            border: Border.all(
                              color: Color.fromARGB(1, 255, 38, 0),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Дата
                              Expanded(
                                child: Container(
                                  height: context.adaptiveSize(40),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: BaseColors.line,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                        context.adaptiveSize(32),
                                      ),
                                      bottomLeft: Radius.circular(
                                        context.adaptiveSize(32),
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      selectedCheckIn != null &&
                                              selectedCheckOut != null
                                          ? "${DateFormat('dd MMM').format(selectedCheckIn!)} - ${DateFormat('dd MMM').format(selectedCheckOut!)}"
                                          : "Select dates",
                                      style: context.adaptiveTextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: BaseColors.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Гости
                              Expanded(
                                child: Container(
                                  height: context.adaptiveSize(40),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: BaseColors.line,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(
                                        context.adaptiveSize(32),
                                      ),
                                      bottomRight: Radius.circular(
                                        context.adaptiveSize(32),
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "$selectedAdults adult${selectedAdults > 1 ? 's' : ''} + $selectedChildren child${selectedChildren != 1 ? 'ren' : ''}",
                                      style: context.adaptiveTextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: BaseColors.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: context.adaptiveSize(16)),

                      // Остальной UI (фото, описание, иконки и т.д.)
                      Column(
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
                                    itemCount: _apartment.imageUrl.length,
                                    itemBuilder: (context, index) {
                                      return CachedNetworkImage(
                                        imageUrl: _apartment.imageUrl[index],
                                        placeholder:
                                            (context, url) =>
                                                CircularProgressIndicator(),
                                        errorWidget:
                                            (context, url, error) =>
                                                Icon(Icons.error),
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                right: context.adaptiveSize(24),
                                top: context.adaptiveSize(24),
                                child: BlocBuilder<
                                  BookmarksCubit,
                                  List<Bookmark>
                                >(
                                  builder: (context, bookmarks) {
                                    final isBookmarked = context
                                        .read<BookmarksCubit>()
                                        .isBookmarked(_apartment as CardData);
                                    return GestureDetector(
                                      onTap: () {
                                        context
                                            .read<BookmarksCubit>()
                                            .toggleBookmark(
                                              _apartment as CardData,
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
                                  widget.apartment.imageUrl.length,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.adaptiveSize(12)),

                          // Название и цена
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _apartment.title,
                                  softWrap: true,
                                  style: context
                                      .adaptiveTextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: BaseColors.text,
                                      )
                                      .copyWith(height: 1.4),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: context.adaptiveSize(24),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Per night:",
                                      style: context
                                          .adaptiveTextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: BaseColors.text,
                                          )
                                          .copyWith(height: 1),
                                    ),
                                    SizedBox(height: context.adaptiveSize(5)),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          _apartment.price.toStringAsFixed(0),
                                          style: context
                                              .adaptiveTextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: BaseColors.accent,
                                              )
                                              .copyWith(height: 1),
                                        ),
                                        Text(
                                          " €",
                                          style: context
                                              .adaptiveTextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: BaseColors.accent,
                                              )
                                              .copyWith(height: 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.adaptiveSize(16)),
                          Text(
                            _apartment.description,
                            style: context.adaptiveTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color.fromARGB(255, 130, 130, 130),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.adaptiveSize(24)),

                      // Иконки сервисов
                      Row(
                        children: [
                          if (_currentPage1 > 0)
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: context.adaptiveSize(16),
                              ),
                              onPressed: _scrollLeft,
                            ),
                          Expanded(
                            child: SizedBox(
                              height: context.adaptiveSize(48),
                              child: ListView.builder(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: icons.length,
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
                                        color: Color.fromARGB(
                                          255,
                                          224,
                                          224,
                                          224,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Color.fromARGB(
                                        0,
                                        1,
                                        1,
                                        1,
                                      ),
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
                                size: context.adaptiveSize(12),
                                color: Color.fromARGB(255, 189, 189, 189),
                              ),
                              onPressed: _scrollRight,
                            ),
                        ],
                      ),
                      SizedBox(height: context.adaptiveSize(40)),
                      GreyLine(),
                      SizedBox(height: context.adaptiveSize(24)),

                      // Рейтинг
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _apartment.rating.toString(),
                                style: context.adaptiveTextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: BaseColors.accent,
                                ),
                              ),
                              SizedBox(width: context.adaptiveSize(6)),
                              StarRating(rating: _apartment.rating),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${_apartment.numberReviews} guest reviews",
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
                      SizedBox(height: context.adaptiveSize(24)),
                      GreyLine(),
                      SizedBox(height: context.adaptiveSize(40)),

                      // Карта
                      ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(context.adaptiveSize(22)),
                        ),
                        child: Container(
                          height: 100,
                          color: BaseColors.primary,
                        ),
                      ),
                      SizedBox(height: context.adaptiveSize(16)),

                      // Адрес
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address:',
                            softWrap: true,
                            style: context.adaptiveTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color.fromARGB(255, 109, 109, 109),
                            ),
                          ),
                          SizedBox(
                            width: context.adaptiveSize(167),
                            child: Text(
                              _apartment.address,
                              style: context.adaptiveTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color.fromARGB(255, 109, 109, 109),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.adaptiveSize(40)),

                      // ✅ Кнопка Booking с обновлённой ценой
                      GestureDetector(
                        onTap: _handleBooking,
                        child: CustomTextFieldWithGradientButton(
                          text: "${totalPrice.toStringAsFixed(0)} €",
                          style: context.adaptiveTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BaseColors.text,
                          ),
                        ),
                      ),
                      SizedBox(height: context.adaptiveSize(20)),
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
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final filledStars = (rating / 2).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        final isFilled = starIndex < filledStars;
        return Padding(
          padding: EdgeInsets.only(right: 1),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_border_rounded,
            color: BaseColors.accent,
            size: 22,
          ),
        );
      }),
    );
  }
}
