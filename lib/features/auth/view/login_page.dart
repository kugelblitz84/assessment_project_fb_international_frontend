import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/route_access_policy.dart';
import 'auth_form_helpers.dart';
import '../controller/auth_form_controller.dart';
import '../model/auth_form_state.dart';
import 'widgets/auth_layout.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authFormControllerProvider(AuthFormMode.login).notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFormControllerProvider(AuthFormMode.login));
    return AuthLayout(
      title: 'Log in to AutoCare',
      subtitle: 'Welcome back. Your next appointment starts here.',
      busy: state.submitting,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ref.watch(sessionProvider).asData?.value case Unauthenticated(
                message: final String message,
              )) ...[
                InlineNotice(message: message),
                SizedBox(height: AppSize.vertical(16)),
              ],
              TextFormField(
                controller: _email,
                enabled: !state.submitting,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
                validator: validateEmail,
              ),
              SizedBox(height: AppSize.vertical(20)),
              TextFormField(
                controller: _password,
                enabled: !state.submitting,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: state.submitting
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: validatePassword,
              ),
              SizedBox(height: AppSize.vertical(24)),
              if (state.error != null) ...[
                InlineNotice(message: state.error!, error: true),
                SizedBox(height: AppSize.vertical(16)),
              ],
              AppButton(
                label: state.submitting ? 'Logging in…' : 'Log in',
                loading: state.submitting,
                onPressed: _submit,
              ),
              SizedBox(height: AppSize.vertical(12)),
              TextButton(
                onPressed: state.submitting
                    ? null
                    : () => context.goNamed(
                        AppRoutes.register,
                        queryParameters: RouteAccessPolicy.redirectParameters(
                          GoRouterState.of(context).uri,
                        ),
                      ),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
