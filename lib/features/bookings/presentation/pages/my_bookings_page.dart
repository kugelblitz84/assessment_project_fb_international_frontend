import 'package:flutter/material.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My bookings')),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Upcoming and previous bookings coming soon.'),
    ),
  );
}
