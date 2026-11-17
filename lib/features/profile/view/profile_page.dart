import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';

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
    final session = ref.watch(sessionProvider);
    return AdaptiveAppShell(
      primary: true,
      title: 'Profile',
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your AutoCare',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'A home for your account and appointments.',
                style: TextStyle(color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              if (user != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primary,
                            child: Text(
                              Formatters.initials(user.name),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          user.email,
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _loggingOut
                              ? null
                              : () => context.pushNamed(AppRoutes.editProfile),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('My bookings'),
                        subtitle: const Text('View and manage appointments'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _loggingOut
                            ? null
                            : () => context.goNamed(AppRoutes.myBookings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.auto_awesome_outlined),
                        title: const Text('AI assistant'),
                        subtitle: const Text(
                          'Find the right care for your car',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _loggingOut
                            ? null
                            : () => context.goNamed(AppRoutes.assistant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  InlineNotice(message: _error!, error: true),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: _loggingOut ? 'Logging out…' : 'Log out',
                  icon: Icons.logout,
                  loading: _loggingOut,
                  onPressed: _logout,
                ),
              ] else ...[
                if (session.asData?.value case Unauthenticated(
                  message: final String message,
                )) ...[
                  InlineNotice(message: message),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primarySoft,
                            child: Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Sign in to manage appointments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Browse AutoCare as a guest. Create an account when you’re ready to book and keep all your appointments together.',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.goNamed(AppRoutes.login),
                          child: const Text('Login'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.goNamed(AppRoutes.register),
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (session.hasError) ...[
                  const SizedBox(height: 20),
                  const InlineNotice(
                    message:
                        'Your session could not be restored. You can keep browsing or retry.',
                    error: true,
                  ),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(sessionProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry session restoration'),
                  ),
                ],
              ],
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'AutoCare · Smart car service booking',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
