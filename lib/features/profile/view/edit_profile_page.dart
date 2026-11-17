import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../controller/profile_controller.dart';
import '../model/update_profile_payload.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(profileControllerProvider.notifier)
        .save(
          UpdateProfilePayload(
            name: _name.text.trim(),
            email: _email.text.trim(),
          ),
        );
    if (saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoutes.profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    return AdaptiveAppShell(
      title: 'Edit profile',
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 560,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your details',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep your account information up to date.',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _name,
                      enabled: !state.saving,
                      decoration: const InputDecoration(labelText: 'Name'),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      enabled: !state.saving,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      validator: Validators.email,
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 24),
                    if (state.errorCode != null) ...[
                      InlineNotice(
                        message: ApiErrorHandler.messageFor(state.errorCode),
                        error: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppButton(
                      label: state.saving ? 'Saving…' : 'Save changes',
                      loading: state.saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
