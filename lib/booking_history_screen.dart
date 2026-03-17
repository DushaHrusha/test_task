import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_task/core/adaptive_size_extension.dart';
import 'package:test_task/core/constants/base_colors.dart';
import 'package:test_task/core/constants/bottom_bar.dart';
import 'package:test_task/core/constants/custom_app_bar.dart';
import 'package:test_task/core/constants/custom_background_with_gradient.dart';
import 'package:test_task/core/constants/grey_line.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test_task/presentation/booking_cubit.dart';
import 'package:test_task/unified_booking.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<UnifiedBookingCubit>().loadAllBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseColors.background,
      body: CustomBackgroundWithGradient(
        child: Column(
          children: [
            const CustomAppBar(label: "Booking History"),
            const GreyLine(),
            SizedBox(height: context.adaptiveSize(16)),
            Expanded(
              child: BlocBuilder<UnifiedBookingCubit, BookingState>(
                builder: (context, state) {
                  if (state is BookingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is BookingError) {
                    return _buildErrorView(state.message);
                  }

                  if (state is BookingsLoaded) {
                    return _buildBookingsTab(state.all, isUpcoming: true);
                  }

                  return _buildEmptyView();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomBar(
        currentScreen: BookingHistoryScreen(),
      ),
    );
  }

  Widget _buildBookingsTab(
    List<UnifiedBooking> bookings, {
    required bool isUpcoming,
  }) {
    if (bookings.isEmpty) {
      return _buildEmptyView(
        message: isUpcoming ? 'No upcoming bookings' : 'No past bookings',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: context.adaptiveSize(30),
        vertical: context.adaptiveSize(16),
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];

        if (booking is ApartmentBooking) {
          return _buildApartmentCard(booking, isUpcoming: isUpcoming);
        } else if (booking is ExcursionBooking) {
          return _buildExcursionCard(booking, isUpcoming: isUpcoming);
        } else if (booking is VehicleBooking) {
          return _buildVehicleCard(booking, isUpcoming: isUpcoming);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildApartmentCard(
    ApartmentBooking booking, {
    required bool isUpcoming,
  }) {
    final apartment = booking.apartment;
    print('🖼️ Apartment imageUrl: ${apartment?.imageUrl}');
    if (apartment?.imageUrl?.isNotEmpty == true) {
      print('🖼️ First image: ${apartment!.imageUrl!.first}');
    }
    return _buildBookingCardBase(
      type: 'Apartment',
      typeIcon: Icons.apartment,
      title: apartment?.title ?? 'Unknown Apartment',
      imageUrl:
          apartment?.imageUrl?.isNotEmpty == true
              ? apartment!.imageUrl!.first
              : null,
      status: booking.status,
      isUpcoming: isUpcoming,
      bookingId: booking.id,
      bookingType: BookingType.apartment,
      price: booking.totalPrice,
      children: [
        _buildInfoRow(
          Icons.calendar_today_outlined,
          '${DateFormat('MMM dd').format(booking.checkInDate)} - ${DateFormat('MMM dd, yyyy').format(booking.checkOutDate)}',
        ),
        SizedBox(height: context.adaptiveSize(8)),
        _buildInfoRow(
          Icons.people_outline,
          '${booking.adults} adult${booking.adults > 1 ? 's' : ''}${booking.children > 0 ? ', ${booking.children} child${booking.children > 1 ? 'ren' : ''}' : ''}',
        ),
        SizedBox(height: context.adaptiveSize(8)),
        Text(
          '${booking.nights} night${booking.nights > 1 ? 's' : ''}',
          style: context.adaptiveTextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildExcursionCard(
    ExcursionBooking booking, {
    required bool isUpcoming,
  }) {
    final excursion = booking.excursion;

    return _buildBookingCardBase(
      type: 'Excursion',
      typeIcon: Icons.tour,
      title: excursion?.title ?? 'Unknown Excursion',
      imageUrl:
          excursion?.imageUrl.isNotEmpty == true
              ? excursion!.imageUrl.first
              : null,
      status: booking.status,
      isUpcoming: isUpcoming,
      bookingId: booking.id,
      bookingType: BookingType.excursion,
      price: booking.totalPrice,
      children: [
        _buildInfoRow(
          Icons.calendar_today_outlined,
          DateFormat('MMM dd, yyyy').format(booking.bookingDate),
        ),
        SizedBox(height: context.adaptiveSize(8)),
        _buildInfoRow(
          Icons.people_outline,
          '${booking.adults} adult${booking.adults > 1 ? 's' : ''}${booking.children > 0 ? ', ${booking.children} child${booking.children > 1 ? 'ren' : ''}' : ''}',
        ),
        if (excursion?.duration != null) ...[
          SizedBox(height: context.adaptiveSize(8)),
          _buildInfoRow(Icons.access_time, '${excursion!.duration} hours'),
        ],
      ],
    );
  }

  Widget _buildVehicleCard(VehicleBooking booking, {required bool isUpcoming}) {
    final vehicle = booking.vehicle;

    return _buildBookingCardBase(
      type: 'Vehicle',
      typeIcon: Icons.directions_car,
      title: vehicle?.model ?? 'Unknown Vehicle',
      imageUrl: vehicle?.image,
      status: booking.status,
      isUpcoming: isUpcoming,
      bookingId: booking.id,
      bookingType: BookingType.vehicle,
      price: booking.totalPrice,
      children: [
        _buildInfoRow(
          Icons.calendar_today_outlined,
          '${DateFormat('MMM dd').format(booking.pickupDate)} - ${DateFormat('MMM dd, yyyy').format(booking.returnDate)}',
        ),
        SizedBox(height: context.adaptiveSize(8)),
        _buildInfoRow(
          Icons.people_outline,
          '${booking.passengers} passenger${booking.passengers > 1 ? 's' : ''}',
        ),
        SizedBox(height: context.adaptiveSize(8)),
        Text(
          '${booking.days} day${booking.days > 1 ? 's' : ''}',
          style: context.adaptiveTextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCardBase({
    required String type,
    required IconData typeIcon,
    required String title,
    required String? imageUrl,
    required String status,
    required bool isUpcoming,
    required int bookingId,
    required BookingType bookingType,
    required double price,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.adaptiveSize(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.adaptiveSize(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.adaptiveSize(20)),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: context.adaptiveSize(150),
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(context.adaptiveSize(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.adaptiveSize(8),
                        vertical: context.adaptiveSize(4),
                      ),
                      decoration: BoxDecoration(
                        color: BaseColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          context.adaptiveSize(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(typeIcon, size: 14, color: BaseColors.accent),
                          SizedBox(width: 4),
                          Text(
                            type,
                            style: context.adaptiveTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: BaseColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),

                SizedBox(height: context.adaptiveSize(8)),

                // Title
                Text(
                  title,
                  style: context.adaptiveTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BaseColors.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: context.adaptiveSize(12)),

                ...children,

                SizedBox(height: context.adaptiveSize(12)),
                const Divider(),
                SizedBox(height: context.adaptiveSize(8)),

                // Price & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${price.toStringAsFixed(0)}',
                      style: context.adaptiveTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: BaseColors.accent,
                      ),
                    ),

                    if (isUpcoming && status != 'cancelled')
                      TextButton(
                        onPressed:
                            () => _showCancelDialog(bookingId, bookingType),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(
                          'Cancel',
                          style: context.adaptiveTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: context.adaptiveSize(16), color: Colors.grey[600]),
        SizedBox(width: context.adaptiveSize(8)),
        Expanded(
          child: Text(
            text,
            style: context.adaptiveTextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = 'Confirmed';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.adaptiveSize(12),
        vertical: context.adaptiveSize(6),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.adaptiveSize(12)),
      ),
      child: Text(
        label,
        style: context.adaptiveTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyView({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: context.adaptiveSize(80),
            color: Colors.grey[400],
          ),
          SizedBox(height: context.adaptiveSize(16)),
          Text(
            message ?? 'No bookings yet',
            style: context.adaptiveTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: context.adaptiveSize(80),
            color: Colors.red[300],
          ),
          SizedBox(height: context.adaptiveSize(16)),
          Text(
            'Error loading bookings',
            style: context.adaptiveTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: context.adaptiveSize(8)),
          Text(
            message,
            style: context.adaptiveTextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.adaptiveSize(24)),
          ElevatedButton(
            onPressed: () {
              context.read<UnifiedBookingCubit>().loadAllBookings();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(int bookingId, BookingType bookingType) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
            ),
            title: Text(
              'Cancel Booking',
              style: context.adaptiveTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: BaseColors.text,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel this booking?',
              style: context.adaptiveTextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'No',
                  style: context.adaptiveTextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await context.read<UnifiedBookingCubit>().cancelBooking(
                      bookingId,
                      bookingType,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Yes, Cancel',
                  style: context.adaptiveTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
