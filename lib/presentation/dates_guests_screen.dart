import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_task/api_client.dart';
import 'package:test_task/api_endpoints.dart';
import 'package:test_task/booking.dart';
import 'package:test_task/booking_service.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/data/models/apartment.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/data/models/apartment.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:test_task/data/models/apartment.dart';

class DatesGuestsScreen extends StatefulWidget {
  final Apartment apartment;
  final Function(DateTime checkIn, DateTime checkOut, int adults, int children)?
  onConfirm;

  const DatesGuestsScreen({super.key, required this.apartment, this.onConfirm});

  @override
  State<DatesGuestsScreen> createState() => _DatesGuestsScreenState();
}

class _DatesGuestsScreenState extends State<DatesGuestsScreen> {
  DateTime? selectedCheckIn;
  DateTime? selectedCheckOut;
  int adults = 2;
  int children = 1;

  @override
  void initState() {
    super.initState();
    // ✅ Загружаем забронированные даты через Cubit
    context.read<ApartmentBookingCubit>().getBookedDates(widget.apartment.id);
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final cubit = context.read<ApartmentBookingCubit>();

    DateTime normalizeDate(DateTime date) {
      return DateTime(date.year, date.month, date.day);
    }

    DateTime getInitialDate() {
      DateTime initialDate = normalizeDate(DateTime.now());

      if (cubit.isDateBlocked(initialDate)) {
        for (int i = 1; i <= 365; i++) {
          final nextDate = initialDate.add(Duration(days: i));
          if (!cubit.isDateBlocked(nextDate)) {
            return nextDate;
          }
        }
      }

      return initialDate;
    }

    final DateTime initialDate = getInitialDate();
    final DateTime firstDate = normalizeDate(DateTime.now());
    final DateTime lastDate = normalizeDate(
      DateTime.now().add(Duration(days: 365)),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime date) {
        return !cubit.isDateBlocked(normalizeDate(date));
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BaseColors.accent,
              onPrimary: Colors.white,
              surface: BaseColors.background,
              onSurface: BaseColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedCheckIn = normalizeDate(picked);
        if (selectedCheckOut != null &&
            selectedCheckOut!.isBefore(selectedCheckIn!)) {
          selectedCheckOut = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    if (selectedCheckIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select check-in date first')),
      );
      return;
    }

    final cubit = context.read<ApartmentBookingCubit>();

    DateTime normalizeDate(DateTime date) {
      return DateTime(date.year, date.month, date.day);
    }

    DateTime getInitialCheckOutDate() {
      DateTime initialDate = normalizeDate(
        selectedCheckIn!.add(Duration(days: 1)),
      );

      if (cubit.isDateBlocked(initialDate)) {
        for (int i = 2; i <= 365; i++) {
          final nextDate = normalizeDate(
            selectedCheckIn!.add(Duration(days: i)),
          );
          if (!cubit.isDateBlocked(nextDate)) {
            return nextDate;
          }
        }
      }

      return initialDate;
    }

    final DateTime initialCheckOutDate = getInitialCheckOutDate();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialCheckOutDate,
      firstDate: selectedCheckIn!.add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        final normalizedDate = normalizeDate(date);

        if (!normalizedDate.isAfter(selectedCheckIn!)) {
          return false;
        }

        for (var range in cubit.cachedBookedDates) {
          final checkIn = normalizeDate(range.checkIn);

          if (checkIn.isAfter(selectedCheckIn!) &&
              (checkIn.isBefore(normalizedDate) ||
                  checkIn.isAtSameMomentAs(normalizedDate))) {
            return false;
          }
        }

        return true;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BaseColors.accent,
              onPrimary: Colors.white,
              surface: BaseColors.background,
              onSurface: BaseColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedCheckOut = normalizeDate(picked);
      });
    }
  }

  void _incrementAdults() {
    if (adults < 10) {
      setState(() => adults++);
    }
  }

  void _decrementAdults() {
    if (adults > 1) {
      setState(() => adults--);
    }
  }

  void _incrementChildren() {
    if (children < 10) {
      setState(() => children++);
    }
  }

  void _decrementChildren() {
    if (children > 0) {
      setState(() => children--);
    }
  }

  double _calculateTotalPrice() {
    if (selectedCheckIn == null || selectedCheckOut == null) return 0;
    final nights = selectedCheckOut!.difference(selectedCheckIn!).inDays;
    return widget.apartment.price * nights;
  }

  // ✅ Новая логика: "Select Dates" просто закрывает окно и передаёт данные
  void _handleSelectDates() {
    if (selectedCheckIn == null || selectedCheckOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select check-in and check-out dates')),
      );
      return;
    }

    // Закрываем модальное окно и передаём данные в callback
    Navigator.pop(context);

    if (widget.onConfirm != null) {
      widget.onConfirm!(selectedCheckIn!, selectedCheckOut!, adults, children);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights =
        selectedCheckIn != null && selectedCheckOut != null
            ? selectedCheckOut!.difference(selectedCheckIn!).inDays
            : 0;
    final totalPrice = _calculateTotalPrice();

    return BlocListener<ApartmentBookingCubit, ApartmentBookingState>(
      listener: (context, state) {
        if (state is ApartmentBookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: AlertDialog(
        insetPadding: EdgeInsets.all(0),
        iconPadding: EdgeInsets.all(0),
        titlePadding: EdgeInsets.all(0),
        buttonPadding: EdgeInsets.all(0),
        actionsPadding: EdgeInsets.all(0),
        contentPadding: EdgeInsets.all(0),
        backgroundColor: Color.fromARGB(0, 255, 255, 255),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 314,
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  size: 32,
                  color: BaseColors.background,
                ),
              ),
            ),
            Container(
              width: 297,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                color: BaseColors.background,
              ),
              child: BlocBuilder<ApartmentBookingCubit, ApartmentBookingState>(
                builder: (context, state) {
                  if (state is ApartmentBookingInitial ||
                      (state is ApartmentBookingLoading &&
                          context
                              .read<ApartmentBookingCubit>()
                              .cachedBookedDates
                              .isEmpty)) {
                    return Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 32),
                      Text(
                        'Dates and Guests',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(255, 109, 109, 109),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      GreyLine(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 37),

                            // Check-in & Check-out
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Check-in",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Color.fromARGB(
                                            255,
                                            109,
                                            109,
                                            109,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      GestureDetector(
                                        onTap:
                                            () => _selectCheckInDate(context),
                                        child: Container(
                                          height: 40,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                selectedCheckIn != null
                                                    ? DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(selectedCheckIn!)
                                                    : '--/--/----',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color.fromARGB(
                                                    255,
                                                    109,
                                                    109,
                                                    109,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: Color.fromARGB(
                                                  255,
                                                  189,
                                                  189,
                                                  189,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Check-out",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Color.fromARGB(
                                            255,
                                            109,
                                            109,
                                            109,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      GestureDetector(
                                        onTap:
                                            () => _selectCheckOutDate(context),
                                        child: Container(
                                          height: 40,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                selectedCheckOut != null
                                                    ? DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(selectedCheckOut!)
                                                    : '--/--/----',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color.fromARGB(
                                                    255,
                                                    109,
                                                    109,
                                                    109,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: Color.fromARGB(
                                                  255,
                                                  189,
                                                  189,
                                                  189,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Adults
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Adults",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 109, 109, 109),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _decrementAdults,
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: BaseColors.accent,
                                    ),
                                    Text(
                                      '$adults',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _incrementAdults,
                                      icon: Icon(Icons.add_circle_outline),
                                      color: BaseColors.accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Children
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Children",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 109, 109, 109),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _decrementChildren,
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: BaseColors.accent,
                                    ),
                                    Text(
                                      '$children',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _incrementChildren,
                                      icon: Icon(Icons.add_circle_outline),
                                      color: BaseColors.accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Total price preview
                            if (nights > 0) ...[
                              Divider(
                                height: 1,
                                color: Color.fromARGB(255, 224, 224, 224),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$nights night${nights > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color.fromARGB(255, 109, 109, 109),
                                    ),
                                  ),
                                  Text(
                                    '${totalPrice.toStringAsFixed(0)} €',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: BaseColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                            ],

                            const SizedBox(height: 24),

                            // ✅ Select Dates button (закрывает окно и обновляет UI)
                            GestureDetector(
                              onTap: _handleSelectDates,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      BaseColors.accent,
                                      BaseColors.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    'Select Dates',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== States =====

abstract class ApartmentBookingState extends Equatable {
  const ApartmentBookingState();

  @override
  List<Object?> get props => [];
}

class ApartmentBookingInitial extends ApartmentBookingState {}

class ApartmentBookingLoading extends ApartmentBookingState {}

class ApartmentBookingDatesLoaded extends ApartmentBookingState {
  final List<BookedDateRange> bookedDates;

  const ApartmentBookingDatesLoaded(this.bookedDates);

  @override
  List<Object?> get props => [bookedDates];
}

class ApartmentBookingSuccess extends ApartmentBookingState {
  final Booking booking;

  const ApartmentBookingSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ApartmentBookingError extends ApartmentBookingState {
  final String message;

  const ApartmentBookingError(this.message);

  @override
  List<Object?> get props => [message];
}

// ===== Cubit =====

class ApartmentBookingCubit extends Cubit<ApartmentBookingState> {
  final BookingsRepository _repository;
  List<BookedDateRange> _cachedBookedDates = [];

  ApartmentBookingCubit(this._repository) : super(ApartmentBookingInitial());

  /// Получить кэшированные забронированные даты
  List<BookedDateRange> get cachedBookedDates => _cachedBookedDates;

  /// ✅ Загрузить забронированные даты (с fallback на пустой список)
  Future<List<BookedDateRange>> getBookedDates(int apartmentId) async {
    try {
      print('🗓️ Loading booked dates for apartment #$apartmentId');

      final bookedDates = await _repository.getBookedDates(apartmentId);
      _cachedBookedDates = bookedDates;

      emit(ApartmentBookingDatesLoaded(bookedDates));

      print('✅ Loaded ${bookedDates.length} booked date ranges');
      for (var range in bookedDates) {
        print(
          '   - ${range.checkIn.toString().split(' ')[0]} → ${range.checkOut.toString().split(' ')[0]}',
        );
      }

      return bookedDates;
    } catch (e) {
      print('⚠️ Warning: Could not load booked dates: $e');

      // ✅ Вместо rethrow просто возвращаем пустой список
      // Это позволит пользователю выбрать даты без интернета
      _cachedBookedDates = [];
      emit(ApartmentBookingDatesLoaded([]));

      return [];
    }
  }

  /// ✅ Проверить доступность дат (с fallback)
  Future<bool> checkAvailability({
    required int apartmentId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      print('🔍 Checking availability for apartment #$apartmentId');

      final isAvailable = await _repository.checkAvailability(
        apartmentId: apartmentId,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      print(isAvailable ? '✅ Dates available' : '❌ Dates not available');
      return isAvailable;
    } catch (e) {
      print('⚠️ Warning: Could not check availability online: $e');

      // ✅ Offline fallback: проверяем по кэшированным данным
      return !_hasLocalConflict(checkIn, checkOut);
    }
  }

  /// ✅ Локальная проверка конфликтов (работает без интернета)
  bool _hasLocalConflict(DateTime checkIn, DateTime checkOut) {
    final normalizedCheckIn = DateTime(
      checkIn.year,
      checkIn.month,
      checkIn.day,
    );
    final normalizedCheckOut = DateTime(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    );

    for (var range in _cachedBookedDates) {
      final bookedCheckIn = DateTime(
        range.checkIn.year,
        range.checkIn.month,
        range.checkIn.day,
      );
      final bookedCheckOut = DateTime(
        range.checkOut.year,
        range.checkOut.month,
        range.checkOut.day,
      );

      // Проверяем пересечение
      if ((normalizedCheckIn.isBefore(bookedCheckOut) &&
              normalizedCheckOut.isAfter(bookedCheckIn)) ||
          normalizedCheckIn.isAtSameMomentAs(bookedCheckIn) ||
          normalizedCheckOut.isAtSameMomentAs(bookedCheckOut)) {
        return true; // Конфликт найден
      }
    }

    return false; // Конфликтов нет
  }

  /// ✅ Создать бронирование (требует интернет)
  /// ✅ Создать бронирование (требует интернет)
  Future<void> createBooking({
    required int apartmentId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
  }) async {
    emit(ApartmentBookingLoading());

    try {
      print('📝 Creating booking for apartment #$apartmentId');

      final booking = await _repository.createBooking(
        apartmentId: apartmentId,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
      );

      print('✅ Booking created successfully: #${booking.id}');
      emit(ApartmentBookingSuccess(booking));
    } catch (e) {
      print('❌ Error creating booking: $e');

      // ✅ Проверяем тип ошибки
      String errorMessage = 'Failed to create booking';

      if (e.toString().contains('No internet connection') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Please connect to the internet to complete booking';
      } else {
        errorMessage = e.toString();
      }

      emit(ApartmentBookingError(errorMessage));
      // ❌ Убираем rethrow! Просто эмитим ошибку
    }
  }

  /// ✅ Проверить, заблокирована ли дата (работает offline)
  bool isDateBlocked(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    for (var range in _cachedBookedDates) {
      final checkIn = DateTime(
        range.checkIn.year,
        range.checkIn.month,
        range.checkIn.day,
      );
      final checkOut = DateTime(
        range.checkOut.year,
        range.checkOut.month,
        range.checkOut.day,
      );

      if ((normalizedDate.isAfter(checkIn) ||
              normalizedDate.isAtSameMomentAs(checkIn)) &&
          normalizedDate.isBefore(checkOut)) {
        return true;
      }
    }

    return false;
  }

  /// ✅ Найти ближайшую свободную дату
  DateTime? findNextAvailableDate(DateTime startDate, {int maxDays = 365}) {
    DateTime normalizeDate(DateTime date) {
      return DateTime(date.year, date.month, date.day);
    }

    DateTime currentDate = normalizeDate(startDate);

    for (int i = 0; i < maxDays; i++) {
      if (!isDateBlocked(currentDate)) {
        return currentDate;
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    return null;
  }

  /// ✅ Получить все заблокированные даты в диапазоне
  List<DateTime> getBlockedDatesInRange(DateTime start, DateTime end) {
    final blockedDates = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endNormalized) ||
        current.isAtSameMomentAs(endNormalized)) {
      if (isDateBlocked(current)) {
        blockedDates.add(current);
      }
      current = current.add(Duration(days: 1));
    }

    return blockedDates;
  }
}

abstract class BookingsRepository {
  /// Получить забронированные даты для апартамента
  Future<List<BookedDateRange>> getBookedDates(int apartmentId);

  /// Проверить доступность дат
  Future<bool> checkAvailability({
    required int apartmentId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Создать бронирование
  Future<Booking> createBooking({
    required int apartmentId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    String? notes,
  });
}

/// Модель для диапазона забронированных дат
class BookedDateRange {
  final DateTime checkIn;
  final DateTime checkOut;

  BookedDateRange({required this.checkIn, required this.checkOut});

  factory BookedDateRange.fromJson(Map<String, dynamic> json) {
    return BookedDateRange(
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'check_in': checkIn.toIso8601String().split('T')[0],
      'check_out': checkOut.toIso8601String().split('T')[0],
    };
  }
}

// Импорт для Booking
class Booking {
  final int id;
  final int apartmentId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int children;
  final double totalPrice;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final dynamic apartment;

  Booking({
    required this.id,
    required this.apartmentId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    this.apartment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      apartmentId: json['apartment_id'] as int,
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      adults: json['adults'] as int,
      children: (json['children'] as int?) ?? 0,
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      apartment: json['apartment'],
    );
  }
}

class BookingsRepositoryImpl implements BookingsRepository {
  final ApiClient _apiClient;

  BookingsRepositoryImpl(this._apiClient);

  @override
  Future<List<BookedDateRange>> getBookedDates(int apartmentId) async {
    try {
      print('🗓️ Fetching booked dates for apartment #$apartmentId');

      final response = await _apiClient.get(
        ApiEndpoints.apartmentBookedDates(apartmentId),
      );

      if (response.data['success'] == true) {
        final List bookedDatesJson =
            response.data['data']['booked_dates'] as List;

        final bookedDates =
            bookedDatesJson
                .map(
                  (json) =>
                      BookedDateRange.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        print('✅ Loaded ${bookedDates.length} booked date ranges');
        return bookedDates;
      } else {
        throw Exception('Failed to load booked dates');
      }
    } catch (e) {
      print('❌ Error loading booked dates: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkAvailability({
    required int apartmentId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      print('🔍 Checking availability for apartment #$apartmentId');
      print('   Check-in: ${checkIn.toIso8601String().split('T')[0]}');
      print('   Check-out: ${checkOut.toIso8601String().split('T')[0]}');

      final response = await _apiClient.post(
        ApiEndpoints.checkApartmentAvailability(apartmentId),
        data: {
          'check_in_date': checkIn.toIso8601String().split('T')[0],
          'check_out_date': checkOut.toIso8601String().split('T')[0],
        },
      );

      if (response.data['success'] == true) {
        final available = response.data['data']['available'] as bool;
        print(available ? '✅ Dates available' : '❌ Dates not available');
        return available;
      } else {
        throw Exception('Failed to check availability');
      }
    } catch (e) {
      print('❌ Error checking availability: $e');
      rethrow;
    }
  }

  @override
  Future<Booking> createBooking({
    required int apartmentId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    String? notes,
  }) async {
    try {
      print('📝 Creating booking for apartment #$apartmentId');

      final response = await _apiClient.post(
        ApiEndpoints.bookings,
        data: {
          'apartment_id': apartmentId,
          'check_in_date': checkIn.toIso8601String().split('T')[0],
          'check_out_date': checkOut.toIso8601String().split('T')[0],
          'adults': adults,
          'children': children,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        final booking = Booking.fromJson(
          response.data['data']['booking'] as Map<String, dynamic>,
        );
        print('✅ Booking created successfully: #${booking.id}');
        return booking;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      print('❌ Error creating booking: $e');
      rethrow;
    }
  }
}
