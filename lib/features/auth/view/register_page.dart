import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../routes/route_access_policy.dart';
import '../controller/auth_form_controller.dart';
import '../model/auth_form_state.dart';
import 'widgets/auth_form.dart';
import 'widgets/auth_layout.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = authFormControllerProvider(AuthFormMode.register);
    final state = ref.watch(provider);
    final controller = ref.watch(provider.notifier);
    return AuthLayout(
      title: 'Create your account',
      subtitle: 'Good care starts with a simple step.',
      busy: state.submitting,
      child: AuthForm(
        key: const ValueKey(AuthFormMode.register),
        mode: AuthFormMode.register,
        submitting: state.submitting,
        error: state.error,
        onSubmit: controller.submit,
        onSwitchMode: state.submitting
            ? null
            : () => context.goNamed(
                AppRoutes.login,
                queryParameters: RouteAccessPolicy.redirectParameters(
                  GoRouterState.of(context).uri,
                ),
              ),
      ),
    );
  }
}
