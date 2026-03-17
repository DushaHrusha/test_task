import 'package:test_task/api_client.dart';
import 'package:test_task/unified_booking.dart';

class UnifiedBookingService {
  final ApiClient _apiClient;

  UnifiedBookingService(this._apiClient);

  Future<Map<String, List<UnifiedBooking>>> getAllBookings() async {
    try {
      final response = await _apiClient.get('/user/all-bookings');

      if (response.data['success'] == true) {
        final data = response.data['data'];

        final List<UnifiedBooking> allBookings = [];

        // Apartments
        if (data['apartment_bookings'] != null) {
          for (var booking in data['apartment_bookings']) {
            allBookings.add(ApartmentBooking.fromJson(booking));
          }
        }

        // Excursions
        if (data['excursion_bookings'] != null) {
          for (var booking in data['excursion_bookings']) {
            allBookings.add(ExcursionBooking.fromJson(booking));
          }
        }

        // Vehicles
        if (data['vehicle_bookings'] != null) {
          for (var booking in data['vehicle_bookings']) {
            allBookings.add(VehicleBooking.fromJson(booking));
          }
        }

        // Sort by date
        allBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

        return {'all': allBookings};
      }

      throw Exception('Failed to load bookings');
    } catch (e) {
      throw Exception('Error loading bookings: $e');
    }
  }

  Future<void> cancelBooking(int bookingId, BookingType type) async {
    String endpoint;

    switch (type) {
      case BookingType.apartment:
        endpoint = '/apartment-bookings/$bookingId/cancel';
        break;
      case BookingType.excursion:
        endpoint = '/excursion-bookings/$bookingId/cancel';
        break;
      case BookingType.vehicle:
        endpoint = '/vehicle-bookings/$bookingId/cancel';
        break;
    }

    try {
      await _apiClient.post(endpoint);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
