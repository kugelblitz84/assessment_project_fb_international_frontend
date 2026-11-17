import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/route_access_policy.dart';
import '../controller/auth_form_controller.dart';
import '../model/auth_form_state.dart';
import 'widgets/auth_form.dart';
import 'widgets/auth_layout.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = authFormControllerProvider(AuthFormMode.login);
    final state = ref.watch(provider);
    final controller = ref.watch(provider.notifier);
    final notice = ref.watch(
      sessionProvider.select(
        (session) => switch (session.asData?.value) {
          Unauthenticated(:final message) => message,
          _ => null,
        },
      ),
    );
    return AuthLayout(
      title: 'Log in to AutoCare',
      subtitle: 'Welcome back. Your next appointment starts here.',
      busy: state.submitting,
      child: AuthForm(
        key: const ValueKey(AuthFormMode.login),
        mode: AuthFormMode.login,
        submitting: state.submitting,
        error: state.error,
        notice: notice,
        onSubmit: controller.submit,
        onSwitchMode: state.submitting
            ? null
            : () => context.goNamed(
                AppRoutes.register,
                queryParameters: RouteAccessPolicy.redirectParameters(
                  GoRouterState.of(context).uri,
                ),
              ),
      ),
    );
  }
}
