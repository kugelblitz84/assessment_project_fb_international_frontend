import 'package:flutter/material.dart';

import '../../navigation/presentation/auto_care_brand.dart';

class BootstrapView extends StatelessWidget {
  const BootstrapView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoCareBrand(),
          SizedBox(height: 32),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Starting AutoCare...'),
        ],
      ),
    ),
  );
}
