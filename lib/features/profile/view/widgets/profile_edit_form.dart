import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../model/update_profile_payload.dart';

class ProfileEditForm extends StatefulWidget {
  const ProfileEditForm({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.saving,
    required this.onSubmit,
    this.error,
  });

  final String initialName;
  final String initialEmail;
  final bool saving;
  final ValueChanged<UpdateProfilePayload> onSubmit;
  final Widget? error;

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    // Initial values are read once so unrelated rebuilds cannot erase a draft.
    _name = TextEditingController(text: widget.initialName);
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit(
      UpdateProfilePayload(name: _name.text.trim(), email: _email.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          enabled: !widget.saving,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter your name.' : null,
        ),
        SizedBox(height: AppSize.vertical(20)),
        TextFormField(
          controller: _email,
          enabled: !widget.saving,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          validator: Validators.email,
          onFieldSubmitted: (_) => _submit(),
        ),
        SizedBox(height: AppSize.vertical(24)),
        if (widget.error != null) ...[
          widget.error!,
          SizedBox(height: AppSize.vertical(16)),
        ],
        AppButton(
          label: widget.saving ? 'Saving\u2026' : 'Save changes',
          loading: widget.saving,
          onPressed: _submit,
        ),
      ],
    ),
  );
}
