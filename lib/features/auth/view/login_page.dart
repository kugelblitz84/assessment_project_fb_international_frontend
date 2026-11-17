import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/route_access_policy.dart';
import 'auth_form_helpers.dart';
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
  bool _submitting = false;
  bool _obscure = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .login(email: _email.text.trim(), password: _password.text);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Log in to AutoCare',
    subtitle: 'Welcome back. Your next appointment starts here.',
    busy: _submitting,
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
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              enabled: !_submitting,
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
            const SizedBox(height: 20),
            TextFormField(
              controller: _password,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: _submitting
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
            const SizedBox(height: 24),
            if (_error != null) ...[
              InlineNotice(message: _error!, error: true),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: _submitting ? 'Logging in…' : 'Log in',
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _submitting
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
