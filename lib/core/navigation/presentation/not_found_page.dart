import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This AutoCare page does not exist.'),
          TextButton(
            onPressed: () => context.goNamed(AppRoutes.home),
            child: const Text('Go to home'),
          ),
        ],
      ),
    ),
  );
}
