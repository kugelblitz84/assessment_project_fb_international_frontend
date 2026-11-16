import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/application/current_user_provider.dart';
import '../../../../core/session/application/session_controller.dart';
import '../../../../routes/app_routes.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _loggingOut = false;
  String? _error;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() {
      _loggingOut = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).logout();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to clear your session. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (user != null) ...[
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loggingOut
                ? null
                : () => context.pushNamed(AppRoutes.editProfile),
            child: const Text('Edit profile'),
          ),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
          FilledButton(
            onPressed: _loggingOut ? null : _logout,
            child: Text(_loggingOut ? 'Logging out...' : 'Log out'),
          ),
        ],
      ),
    );
  }
}
