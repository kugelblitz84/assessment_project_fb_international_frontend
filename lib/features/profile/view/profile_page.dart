import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_surface.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/profile_header.dart';
import '../controller/logout_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logout = ref.watch(logoutControllerProvider);
    final logoutController = ref.watch(logoutControllerProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final session = ref.watch(sessionProvider);
    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your AutoCare',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppSize.vertical(8)),
            const Text(
              'A home for your account and appointments.',
              style: TextStyle(color: AppColors.secondary),
            ),
            SizedBox(height: AppSize.vertical(24)),
            if (user != null) ...[
              ProfileHeader(
                user: user,
                onEdit: logout.loading
                    ? null
                    : () => context.pushNamed(AppRoutes.editProfile),
              ),
              SizedBox(height: AppSize.vertical(20)),
              AppSurface(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSize.horizontal(20),
                        vertical: AppSize.vertical(8),
                      ),
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('My bookings'),
                      subtitle: const Text('View and manage appointments'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: logout.loading
                          ? null
                          : () => context.goNamed(AppRoutes.myBookings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSize.horizontal(20),
                        vertical: AppSize.vertical(8),
                      ),
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: const Text('AI assistant'),
                      subtitle: const Text('Find the right care for your car'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: logout.loading
                          ? null
                          : () => context.goNamed(AppRoutes.assistant),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSize.vertical(24)),
              if (logout.error != null) ...[
                InlineNotice(message: logout.error!, error: true),
                SizedBox(height: AppSize.vertical(16)),
              ],
              AppButton(
                label: logout.loading ? 'Logging out…' : 'Log out',
                icon: Icons.logout,
                loading: logout.loading,
                onPressed: logoutController.logout,
              ),
            ] else ...[
              if (session.asData?.value case Unauthenticated(
                message: final String message,
              )) ...[
                InlineNotice(message: message),
                SizedBox(height: AppSize.vertical(16)),
              ],
              AppSurface(
                child: Padding(
                  padding: AppSize.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: AppSize.radius(32),
                          backgroundColor: AppColors.primarySoft,
                          child: Icon(
                            Icons.person_outline,
                            color: AppColors.primary,
                            size: AppSize.icon(34),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.vertical(24)),
                      Text(
                        'Sign in to manage appointments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: AppSize.vertical(12)),
                      const Text(
                        'Browse AutoCare as a guest. Create an account when you’re ready to book and keep all your appointments together.',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                      SizedBox(height: AppSize.vertical(24)),
                      FilledButton(
                        onPressed: () => context.goNamed(AppRoutes.login),
                        child: const Text('Login'),
                      ),
                      SizedBox(height: AppSize.vertical(12)),
                      OutlinedButton(
                        onPressed: () => context.goNamed(AppRoutes.register),
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ),
              ),
              if (session.hasError) ...[
                SizedBox(height: AppSize.vertical(20)),
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
            SizedBox(height: AppSize.vertical(28)),
            Center(
              child: Text(
                'AutoCare · Smart car service booking',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: AppSize.font(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
