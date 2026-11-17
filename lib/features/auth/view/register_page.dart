import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/route_access_policy.dart';
import 'auth_form_helpers.dart';
import '../controller/auth_form_controller.dart';
import '../model/auth_form_state.dart';
import 'widgets/auth_layout.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authFormControllerProvider(AuthFormMode.register).notifier)
        .submit(email: _email.text, password: _password.text, name: _name.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFormControllerProvider(AuthFormMode.register));
    return AuthLayout(
      title: 'Create your account',
      subtitle: 'Good care starts with a simple step.',
      busy: state.submitting,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                enabled: !state.submitting,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name.'
                    : null,
              ),
              SizedBox(height: AppSize.vertical(20)),
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
                  AutofillHints.newUsername,
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
                autofillHints: const [AutofillHints.newPassword],
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
                label: state.submitting ? 'Creating account…' : 'Register',
                loading: state.submitting,
                onPressed: _submit,
              ),
              SizedBox(height: AppSize.vertical(12)),
              TextButton(
                onPressed: state.submitting
                    ? null
                    : () => context.goNamed(
                        AppRoutes.login,
                        queryParameters: RouteAccessPolicy.redirectParameters(
                          GoRouterState.of(context).uri,
                        ),
                      ),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
