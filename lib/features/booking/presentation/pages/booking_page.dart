import 'package:flutter/material.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Book a service')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Service: $serviceId\nAppointment booking coming soon.'),
    ),
  );
}
