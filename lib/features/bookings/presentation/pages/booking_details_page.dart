import 'package:flutter/material.dart';

class BookingDetailsPage extends StatelessWidget {
  const BookingDetailsPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Booking details')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Booking: $bookingId\nBooking details coming soon.'),
    ),
  );
}
