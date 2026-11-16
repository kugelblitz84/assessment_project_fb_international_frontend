import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/application/current_user_provider.dart';
import '../../../../routes/app_routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AutoCare')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(user == null ? 'Welcome' : 'Welcome, ${user.name}'),
          const SizedBox(height: 16),
          const Text('Service catalogue coming soon.'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pushNamed(AppRoutes.myBookings),
            child: const Text('My bookings'),
          ),
          OutlinedButton(
            onPressed: () => context.pushNamed(AppRoutes.profile),
            child: const Text('Profile'),
          ),
          OutlinedButton(
            onPressed: () => context.pushNamed(AppRoutes.assistant),
            child: const Text('AI assistant'),
          ),
        ],
      ),
    );
  }
}
