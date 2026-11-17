import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/application/session_controller.dart';
import '../../../../core/session/domain/auth_state.dart';
import '../../../../routes/app_routes.dart';
import '../../../../routes/route_access_policy.dart';
import '../auth_form_helpers.dart';

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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Log in to AutoCare')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ref.watch(sessionProvider).asData?.value case Unauthenticated(
                message: final String message,
              ))
                Semantics(liveRegion: true, child: Text(message)),
              const Text('Your car. Expert care. One tap away.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _submit(),
                validator: validatePassword,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Semantics(liveRegion: true, child: Text(_error!)),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Logging in...' : 'Log in'),
              ),
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
    ),
  );
}
