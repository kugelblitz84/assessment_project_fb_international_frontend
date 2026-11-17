import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_validation.dart';

class PasswordFormField extends StatelessWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.onSubmitted,
    this.newPassword = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmitted;
  final bool newPassword;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: obscureText ? 'Show password' : 'Hide password',
        onPressed: enabled ? onToggleVisibility : null,
        icon: Icon(
          obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    obscureText: obscureText,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    onFieldSubmitted: (_) => onSubmitted(),
    validator: AuthValidation.password,
  );
}
