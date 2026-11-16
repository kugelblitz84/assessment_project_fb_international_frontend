import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking confirmation')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking: $bookingId'),
          const Text('Booking confirmation information coming soon.'),
          OutlinedButton(
            onPressed: () => context.goNamed(AppRoutes.myBookings),
            child: const Text('My bookings'),
          ),
        ],
      ),
    ),
  );
}
