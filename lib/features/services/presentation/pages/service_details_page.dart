import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';

class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Service details')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service: $serviceId'),
          const Text('Service information coming soon.'),
          OutlinedButton(
            onPressed: () => context.pushNamed(
              AppRoutes.booking,
              pathParameters: {'serviceId': serviceId},
            ),
            child: const Text('Book this service'),
          ),
        ],
      ),
    ),
  );
}
