import 'package:flutter/material.dart';

class BootstrapView extends StatelessWidget {
  const BootstrapView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Starting AutoCare...'),
        ],
      ),
    ),
  );
}
