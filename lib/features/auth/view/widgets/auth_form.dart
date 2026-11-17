import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/validators.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_button.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/view/widgets/password_form_field.dart';

/// Credentials live only in this mounted form; request state stays in Riverpod.
class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.mode,
    required this.submitting,
    required this.onSubmit,
    required this.onSwitchMode,
    this.error,
    this.notice,
  });

  final AuthFormMode mode;
  final bool submitting;
  final String? error;
  final String? notice;
  final void Function({
    required String email,
    required String password,
    String? name,
  })
  onSubmit;
  final VoidCallback? onSwitchMode;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  bool get _register => widget.mode == AuthFormMode.register;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.submitting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit(
      name: _register ? _name.text : null,
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.notice != null) ...[
            InlineNotice(message: widget.notice!),
            SizedBox(height: AppSize.vertical(16)),
          ],
          if (_register) ...[
            TextFormField(
              controller: _name,
              enabled: !widget.submitting,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidation.name,
            ),
            SizedBox(height: AppSize.vertical(20)),
          ],
          TextFormField(
            controller: _email,
            enabled: !widget.submitting,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: [
              _register ? AutofillHints.newUsername : AutofillHints.username,
              AutofillHints.email,
            ],
            autocorrect: false,
            validator: Validators.email,
          ),
          SizedBox(height: AppSize.vertical(20)),
          PasswordFormField(
            controller: _password,
            enabled: !widget.submitting,
            obscureText: _obscure,
            onToggleVisibility: () => setState(() => _obscure = !_obscure),
            newPassword: _register,
            onSubmitted: _submit,
          ),
          SizedBox(height: AppSize.vertical(24)),
          if (widget.error != null) ...[
            InlineNotice(message: widget.error!, error: true),
            SizedBox(height: AppSize.vertical(16)),
          ],
          AppButton(
            label: widget.submitting
                ? (_register ? 'Creating account\u2026' : 'Logging in\u2026')
                : (_register ? 'Register' : 'Log in'),
            loading: widget.submitting,
            onPressed: _submit,
          ),
          SizedBox(height: AppSize.vertical(12)),
          TextButton(
            onPressed: widget.onSwitchMode,
            child: Text(
              _register
                  ? 'Already have an account? Log in'
                  : 'Create an account',
            ),
          ),
        ],
      ),
    ),
  );
}
