import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_task/unified_booking.dart';
import 'package:test_task/unified_booking_service.dart';

// States
abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<UnifiedBooking> all;

  BookingsLoaded({required this.all});
}

class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

// Cubit
class UnifiedBookingCubit extends Cubit<BookingState> {
  final UnifiedBookingService _bookingService;

  UnifiedBookingCubit(this._bookingService) : super(BookingInitial());

  Future<void> loadAllBookings() async {
    emit(BookingLoading());

    try {
      final bookings = await _bookingService.getAllBookings();

      emit(BookingsLoaded(all: bookings['all']!));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> cancelBooking(int bookingId, BookingType type) async {
    try {
      await _bookingService.cancelBooking(bookingId, type);
      await loadAllBookings(); // Reload after cancel
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
