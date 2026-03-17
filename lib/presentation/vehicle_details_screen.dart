import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:test_task/bloc/cubits/vehicle_cubit.dart';
import 'package:test_task/bloc/state/vehicle_state.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/core/constants/custom_text_field_with_gradient_button.dart';
import 'package:test_task/core/constants/date_picker.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/core/constants/vehicle_booking_service.dart';
import 'package:test_task/data/models/vehicle.dart';
import 'package:test_task/data/repositories/vehicle_repository.dart';
// data/repositories/vehicle_booking_repository.dart

import 'package:dio/dio.dart';
import 'package:test_task/api_client.dart';

abstract class VehicleBookingRepository {
  Future<Map<String, dynamic>> createBooking({
    required int vehicleId,
    required DateTime pickupDate,
    required DateTime returnDate,
    required int passengers,
    required bool airConditioning,
    required bool insurance,
    required bool depositRequired,
    required String currency,
    required double totalPrice, // ✅ добавили
    String? notes,
  });

  Future<bool> checkAvailability({
    required int vehicleId,
    required DateTime pickupDate,
    required DateTime returnDate,
  });
}

class VehicleBookingRepositoryImpl implements VehicleBookingRepository {
  final ApiClient _apiClient;

  VehicleBookingRepositoryImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> createBooking({
    required int vehicleId,
    required DateTime pickupDate,
    required DateTime returnDate,
    required int passengers,
    required bool airConditioning,
    required bool insurance,
    required bool depositRequired,
    required String currency,
    required double totalPrice, // ✅ добавили
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/vehicle-bookings',
        data: {
          'vehicle_id': vehicleId,
          'pickup_date': pickupDate.toIso8601String().split('T')[0],
          'return_date': returnDate.toIso8601String().split('T')[0],
          'passengers': passengers,
          'air_conditioning': airConditioning,
          'insurance': insurance,
          'deposit_required': depositRequired,
          'currency': currency,
          'total_price': totalPrice, // ✅ вот здесь
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']['booking']);
      }

      throw Exception('Booking failed');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('These dates are already booked');
      }
      throw Exception('Failed to create booking: ${e.message}');
    }
  }

  @override
  Future<bool> checkAvailability({
    required int vehicleId,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/vehicles/$vehicleId/check-availability',
        data: {
          'pickup_date': pickupDate.toIso8601String().split('T')[0],
          'return_date': returnDate.toIso8601String().split('T')[0],
        },
      );

      if (response.data['success'] == true) {
        return response.data['data']['available'] as bool;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

abstract class VehicleBookingState {}

class VehicleBookingInitial extends VehicleBookingState {}

class VehicleBookingLoading extends VehicleBookingState {}

class VehicleBookingSuccess extends VehicleBookingState {
  final Map<String, dynamic> booking;
  VehicleBookingSuccess(this.booking);
}

class VehicleBookingError extends VehicleBookingState {
  final String message;
  VehicleBookingError(this.message);
}

class VehicleAvailabilityLoading extends VehicleBookingState {}

class VehicleAvailabilityResult extends VehicleBookingState {
  final bool available;
  VehicleAvailabilityResult(this.available);
}

class VehicleBookingCubit extends Cubit<VehicleBookingState> {
  final VehicleBookingRepository _repository;

  VehicleBookingCubit(this._repository) : super(VehicleBookingInitial());

  Future<void> createBooking({
    required int vehicleId,
    required DateTime pickupDate,
    required DateTime returnDate,
    required int passengers,
    required bool airConditioning,
    required bool insurance,
    required bool depositRequired,
    required String currency,
    String? notes,
    required double totalPrice,
  }) async {
    emit(VehicleBookingLoading());

    try {
      final booking = await _repository.createBooking(
        vehicleId: vehicleId,
        pickupDate: pickupDate,
        returnDate: returnDate,
        passengers: passengers,
        airConditioning: airConditioning,
        insurance: insurance,
        depositRequired: depositRequired,
        currency: currency,
        notes: notes,
        totalPrice: totalPrice,
      );
      emit(VehicleBookingSuccess(booking));
    } catch (e) {
      emit(VehicleBookingError(e.toString()));
    }
  }

  Future<void> checkAvailability({
    required int vehicleId,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    emit(VehicleAvailabilityLoading());

    try {
      final available = await _repository.checkAvailability(
        vehicleId: vehicleId,
        pickupDate: pickupDate,
        returnDate: returnDate,
      );
      emit(VehicleAvailabilityResult(available));
    } catch (e) {
      emit(VehicleBookingError(e.toString()));
    }
  }

  void reset() {
    emit(VehicleBookingInitial());
  }
}

class VehicleDetailsScreen extends StatelessWidget {
  final VehicleRepository vehicleRepository;
  final String label;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleRepository,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Создаём Cubit для этого экрана
      create: (context) => VehicleCubit(repository: vehicleRepository),
      child: _VehicleDetailsScreenContent(label: label),
    );
  }
}

class _VehicleDetailsScreenContent extends StatefulWidget {
  final String label;

  const _VehicleDetailsScreenContent({required this.label});

  @override
  State<_VehicleDetailsScreenContent> createState() =>
      _VehicleDetailsScreenContentState();
}

class _VehicleDetailsScreenContentState
    extends State<_VehicleDetailsScreenContent>
    with TickerProviderStateMixin {
  late AnimationController _stageController;
  final String _selectedDateRange = '--/--/----';
  late AnimationController _stageController1;
  late AnimationController _bottomBarController;
  late AnimationController _appBarController;
  late AnimationController _appBarController1;
  late int sumDay = 0;

  int currentIndex43 = 0;
  final Map<String, String> _icons43 = {
    'type_transmission': 'assets/file/Automatic.svg',
    'number_seats': 'assets/file/Seats.svg',
    'type_fuel': 'assets/file/Gasoline.svg',
    'insurance': 'assets/file/Insurance.svg',
  };

  final ScrollController _scrollController434 = ScrollController();

  late List<Vehicle> vehicle;
  late PageController _pageController43;
  late AnimationController _stageController43;
  DateTime? _pickupDate;
  DateTime? _returnDate;
  late AnimationController _appBarController23;
  late AnimationController _animationTextController32;
  late AnimationController _stageController132;
  late AnimationController _stageController223;
  late String label;

  @override
  void initState() {
    super.initState();
    label = widget.label;

    _pageController43 = PageController(
      initialPage: currentIndex43,
      viewportFraction: 1,
      keepPage: true,
    );
    _appBarController23 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stageController132 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stageController223 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stageController43 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationTextController32 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stageController43.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 0), () {
          _appBarController23.forward().then((_) {
            _stageController132.forward().then((_) {
              _stageController223.forward();
              _animationTextController32.forward();
            });
          });
        });
      }
    });

    _stageController43.forward();

    _appBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _appBarController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stageController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stageController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 0), () {
          _appBarController.forward().then((_) {
            _appBarController1.forward().then((_) {
              _stageController1.forward();
              _bottomBarController.forward();
            });
          });
        });
      }
    });

    _stageController.forward();
  }

  void _nextCar() {
    if (currentIndex43 < vehicle.length - 1) {
      _pageController43.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousCar() {
    if (currentIndex43 > 0) {
      _pageController43.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _stageController43.dispose();
    _appBarController23.dispose();
    _animationTextController32.dispose();
    _stageController132.dispose();
    _stageController223.dispose();
    _pageController43.dispose();
    _scrollController434.dispose();
    _stageController.dispose();
    _stageController1.dispose();
    _bottomBarController.dispose();
    _appBarController.dispose();
    _appBarController1.dispose();
    super.dispose();
  }

  int get _totalDays {
    if (_pickupDate == null || _returnDate == null) return 0;
    return _returnDate!.difference(_pickupDate!).inDays;
  }

  int get _totalPrice {
    if (_totalDays == 0) return 0;
    return vehicle[currentIndex43].pricePerHour * _totalDays;
  }

  String get _formattedDateRange {
    if (_pickupDate == null || _returnDate == null) {
      return '--/--/---- - --/--/----';
    }
    return '${_pickupDate!.day.toString().padLeft(2, '0')}/${_pickupDate!.month.toString().padLeft(2, '0')}/${_pickupDate!.year} - ${_returnDate!.day.toString().padLeft(2, '0')}/${_returnDate!.month.toString().padLeft(2, '0')}/${_returnDate!.year}';
  }

  Future<void> _selectDates() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DatePickerWidget(),
    );

    if (result != null) {
      setState(() {
        _pickupDate = result['pickup'] as DateTime;
        _returnDate = result['return'] as DateTime;
      });
    }
  }

  Widget _buildCharacteristicCircle(String carCh, String iconPath) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 1000),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0.0, 0.5, curve: Curves.linear),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Interval(0.5, 0.8, curve: Curves.linear),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>(vehicle[currentIndex43].year.toString()),
        width: context.adaptiveSize(80),
        height: context.adaptiveSize(80),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 235, 241, 244),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconPath, color: Color.fromARGB(255, 85, 97, 178)),
            SizedBox(height: context.adaptiveSize(6)),
            Text(
              carCh,
              style: context.adaptiveTextStyle(
                fontSize: 10,
                color: Color.fromARGB(255, 85, 97, 178),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<VehicleCubit, VehicleState>(
        builder: (context, state) {
          if (state is VehicleInitial || state is VehicleLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is VehicleLoaded) {
            vehicle = state.vehicles; // Присваиваем vehicles из state

            return CustomBackgroundWithGradient(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _appBarController,
                    builder:
                        (context, child) => Opacity(
                          opacity: _appBarController.value,
                          child: CustomAppBar(label: label),
                        ),
                  ),
                  AnimatedBuilder(
                    animation: _appBarController,
                    builder:
                        (context, child) => Opacity(
                          opacity: _appBarController.value,
                          child: GreyLine(),
                        ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: context.adaptiveSize(20),
                              left: context.adaptiveSize(10),
                              right: context.adaptiveSize(10),
                            ),
                            child: SizedBox(
                              height: context.adaptiveSize(26),
                              child: AnimatedBuilder(
                                animation: _stageController132,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _stageController132.value,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          iconSize: context.adaptiveSize(24),
                                          icon: Icon(
                                            Icons.chevron_left,
                                            size: 28,
                                            color: Color.fromRGBO(
                                              189,
                                              189,
                                              189,
                                              1,
                                            ),
                                          ),
                                          onPressed: _previousCar,
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Select vehicle',
                                            style: context.adaptiveTextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color.fromARGB(
                                                255,
                                                130,
                                                130,
                                                130,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          iconSize: context.adaptiveSize(24),
                                          icon: Icon(
                                            Icons.chevron_right,
                                            size: 28,
                                            color: Color.fromRGBO(
                                              189,
                                              189,
                                              189,
                                              1,
                                            ),
                                          ),
                                          onPressed: _nextCar,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: context.adaptiveSize(27)),
                          AnimatedBuilder(
                            animation: _stageController223,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _stageController223.value,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 30, right: 30),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: Duration(milliseconds: 1000),
                                        transitionBuilder: (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: Text(
                                          key: ValueKey<String>(
                                            vehicle[currentIndex43].year
                                                .toString(),
                                          ),
                                          vehicle[currentIndex43].year
                                              .toString(),
                                          style: context.adaptiveTextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color.fromARGB(
                                              255,
                                              130,
                                              130,
                                              130,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'from:',
                                        style: context.adaptiveTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color.fromARGB(
                                            255,
                                            130,
                                            130,
                                            130,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: context.adaptiveSize(7)),
                          AnimatedBuilder(
                            animation: _stageController223,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _stageController223.value,
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 1000),
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: Padding(
                                    key: ValueKey<String>(
                                      vehicle[currentIndex43].year.toString(),
                                    ),
                                    padding: EdgeInsets.only(
                                      left: context.adaptiveSize(30),
                                      right: context.adaptiveSize(30),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          vehicle[currentIndex43].model,
                                          style: context.adaptiveTextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Color.fromARGB(
                                              255,
                                              109,
                                              109,
                                              109,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              vehicle[currentIndex43]
                                                  .pricePerHour
                                                  .toString(),
                                              key: ValueKey<String>(
                                                'price${vehicle[currentIndex43].pricePerHour}',
                                              ),
                                              style: context.adaptiveTextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  127,
                                                  80,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              ' €',
                                              style: context.adaptiveTextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  127,
                                                  80,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: context.adaptiveSize(8)),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: context.adaptiveSize(30),
                                right: context.adaptiveSize(30),
                              ),
                              child: AnimatedBuilder(
                                animation: _stageController223,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _stageController223.value,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Max speed: ',
                                          style: context.adaptiveTextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color.fromARGB(
                                              255,
                                              130,
                                              130,
                                              130,
                                            ),
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: Duration(
                                            milliseconds: 1000,
                                          ),
                                          transitionBuilder: (
                                            Widget child,
                                            Animation<double> animation,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            key: ValueKey<String>(
                                              vehicle[currentIndex43].year
                                                  .toString(),
                                            ),
                                            "${vehicle[currentIndex43].maxSpeed.toString()} km/h",
                                            style: context.adaptiveTextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color.fromARGB(
                                                255,
                                                130,
                                                130,
                                                130,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _animationTextController32,
                            builder: (context, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationTextController32,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: MediaQuery.widthOf(context),
                                      height: context.adaptiveSize(212),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: context.adaptiveSize(30),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/file/form-bg.svg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          height: context.adaptiveSize(210),
                                          child: PageView.builder(
                                            controller: _pageController43,
                                            itemCount: vehicle.length,
                                            onPageChanged: (index) {
                                              setState(() {
                                                currentIndex43 = index;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              return AnimatedSwitcher(
                                                duration: Duration(
                                                  milliseconds: 500,
                                                ),
                                                switchInCurve: Curves.easeOut,
                                                switchOutCurve: Curves.easeIn,
                                                transitionBuilder: (
                                                  Widget child,
                                                  Animation<double> animation,
                                                ) {
                                                  return SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: Offset(1.0, 0.0),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.easeOut,
                                                      ),
                                                    ),
                                                    child: FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  key: ValueKey<int>(index),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        vehicle[index].image,
                                                    fit: BoxFit.contain,
                                                    height: context
                                                        .adaptiveSize(210),
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(Icons.error),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: context.adaptiveSize(16)),
                          AnimatedBuilder(
                            animation: _animationTextController32,
                            builder: (context, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationTextController32,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                                child: SizedBox(
                                  height: context.adaptiveSize(80),
                                  child: ListView(
                                    controller: _scrollController434,
                                    scrollDirection: Axis.horizontal,
                                    physics: BouncingScrollPhysics(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 30,
                                    ),
                                    children: [
                                      _buildCharacteristicCircle(
                                        vehicle[currentIndex43]
                                            .typeTransmission,
                                        _icons43["type_transmission"]!,
                                      ),
                                      SizedBox(width: context.adaptiveSize(24)),
                                      _buildCharacteristicCircle(
                                        "${vehicle[currentIndex43].numberSeats} Seats",
                                        _icons43["number_seats"]!,
                                      ),
                                      SizedBox(width: context.adaptiveSize(24)),
                                      _buildCharacteristicCircle(
                                        vehicle[currentIndex43].typeFuel,
                                        _icons43["type_fuel"]!,
                                      ),
                                      SizedBox(width: context.adaptiveSize(24)),
                                      _buildCharacteristicCircle(
                                        vehicle[currentIndex43].insurance,
                                        _icons43["insurance"]!,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: context.adaptiveSize(32)),
                          _buildDateSelector(),
                          SizedBox(height: context.adaptiveSize(16)),
                          _buildBookingPanel(),
                          SizedBox(height: context.adaptiveSize(32)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is VehicleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<VehicleCubit>().refreshVehicles();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SizedBox.shrink();
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _bottomBarController,
        builder:
            (context, child) => SlideTransition(
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
            ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return AnimatedBuilder(
      animation: _bottomBarController,
      builder: (context, child) {
        return Opacity(
          opacity: _bottomBarController.value,
          child: Container(
            height: context.adaptiveSize(56),
            margin: EdgeInsets.symmetric(horizontal: context.adaptiveSize(30)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.adaptiveSize(30)),
              color: Color.fromARGB(0, 177, 11, 11),
              border: Border.all(
                color: const Color.fromARGB(255, 224, 224, 224),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Choose dates:',
                      style: context.adaptiveTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 109, 109, 109),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: context.adaptiveSize(56),
                  width: 1,
                  color: const Color.fromARGB(255, 224, 224, 224),
                ),
                SizedBox(
                  width: context.adaptiveSize(170),
                  child: GestureDetector(
                    onTap: () {
                      _selectDates();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedDateRange,
                          style: context.adaptiveTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 109, 109, 109),
                          ),
                        ),
                        SizedBox(width: context.adaptiveSize(8)),
                        Icon(
                          Icons.calendar_today,
                          size: context.adaptiveSize(16),
                          color: Color.fromARGB(255, 109, 109, 109),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingPanel() {
    return AnimatedBuilder(
      animation: _bottomBarController,
      builder: (context, child) {
        return Opacity(
          opacity: _bottomBarController.value,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.adaptiveSize(30)),
            child: Container(
              height: context.adaptiveSize(56),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [BaseColors.accent, BaseColors.primary],
                ),
                borderRadius: BorderRadius.circular(context.adaptiveSize(30)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _totalDays > 0 ? _confirmBooking : null,
                  borderRadius: BorderRadius.circular(context.adaptiveSize(30)),
                  child: Center(
                    child: Text(
                      _totalDays > 0
                          ? '${_totalPrice.toStringAsFixed(0)} € / $_totalDays days - Book Now'
                          : 'Select dates to book',
                      style: context.adaptiveTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Future<void> _confirmBooking() async {
    if (_pickupDate == null || _returnDate == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle: ${vehicle[currentIndex43].model}'),
                SizedBox(height: 8),
                Text(
                  'From: ${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}',
                ),
                Text(
                  'To: ${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
                ),
                Text('Days: $_totalDays'),
                SizedBox(height: 8),
                Text(
                  'Total: ${_totalPrice.toStringAsFixed(2)} €',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BaseColors.accent,
                ),
                child: Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // Показываем загрузку
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      try {
        final cubit = context.read<VehicleBookingCubit>();
        // Создаем бронирование
        await cubit.createBooking(
          vehicleId: vehicle[currentIndex43].id,
          pickupDate: _pickupDate!,
          totalPrice: _totalPrice.toDouble(),
          returnDate: _returnDate!,
          passengers: 2, // Можно добавить выбор количества пассажиров
          airConditioning: true, // Можно добавить опции
          insurance: false,
          depositRequired: true,
          currency: 'EUR',
          notes: 'Booked from mobile app',
        );

        // Закрываем загрузку
        Navigator.pop(context);

        // Показываем успех
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking successful! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Сбрасываем выбранные даты
        setState(() {
          _pickupDate = null;
          _returnDate = null;
        });
      } catch (e) {
        // Закрываем загрузку
        Navigator.pop(context);

        // Показываем ошибку
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class VehicleBookingDialog extends StatefulWidget {
  final int vehicleId;
  final DateTime? pickupDate;
  final DateTime? returnDate;

  const VehicleBookingDialog({
    super.key,
    required this.vehicleId,
    this.pickupDate,
    this.returnDate,
  });

  @override
  State<VehicleBookingDialog> createState() => _VehicleBookingDialogState();
}

class _VehicleBookingDialogState extends State<VehicleBookingDialog> {
  DateTime? _selectedPickupDate;
  DateTime? _selectedReturnDate;

  @override
  void initState() {
    super.initState();
    _selectedPickupDate = widget.pickupDate;
    _selectedReturnDate = widget.returnDate;
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isPickup
              ? (_selectedPickupDate ?? DateTime.now())
              : (_selectedReturnDate ?? _selectedPickupDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _selectedPickupDate = picked;
          // Если return date раньше pickup, сбросить
          if (_selectedReturnDate != null &&
              _selectedReturnDate!.isBefore(picked)) {
            _selectedReturnDate = null;
          }
        } else {
          _selectedReturnDate = picked;
        }
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
            width: 297,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              color: BaseColors.background,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 32),
                Text(
                  'Booking Dates',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 109, 109, 109),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                GreyLine(),
                SizedBox(height: 37),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDateField('Pickup', _selectedPickupDate, true),
                          SizedBox(width: 8),
                          _buildDateField('Return', _selectedReturnDate, false),
                        ],
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed:
                            (_selectedPickupDate != null &&
                                    _selectedReturnDate != null)
                                ? () {
                                  Navigator.pop(context, {
                                    'pickup': _selectedPickupDate!,
                                    'return': _selectedReturnDate!,
                                  });
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Confirm Dates'),
                      ),
                      const SizedBox(height: 41),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isPickup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 109, 109, 109),
          ),
        ),
        GestureDetector(
          onTap: () => _selectDate(context, isPickup),
          child: Container(
            height: 40,
            width: 119,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : '--/--/----',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 109, 109, 109),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color.fromARGB(255, 189, 189, 189),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
