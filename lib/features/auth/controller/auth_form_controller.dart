import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/session_exception.dart';
import '../../../core/utils/validators.dart';
import '../model/auth_form_state.dart';

final authFormControllerProvider = NotifierProvider.autoDispose
    .family<AuthFormController, AuthFormState, AuthFormMode>(
      AuthFormController.new,
    );

class AuthFormController extends Notifier<AuthFormState> {
  AuthFormController(this.mode);
  final AuthFormMode mode;
  @override
  AuthFormState build() => const AuthFormState();

  Future<void> submit({
    required String email,
    required String password,
    String? name,
  }) async {
    if (state.submitting) return;
    final validation =
        Validators.email(email) ??
        (password.isEmpty ? 'Enter your password.' : null) ??
        (mode == AuthFormMode.register && (name == null || name.trim().isEmpty)
            ? 'Enter your name.'
            : null);
    if (validation != null) {
      state = AuthFormState(status: AuthFormStatus.failed, error: validation);
      return;
    }
    state = const AuthFormState(status: AuthFormStatus.submitting);
    try {
      final session = ref.read(sessionProvider.notifier);
      if (mode == AuthFormMode.login) {
        await session.login(email: email.trim(), password: password);
      } else {
        await session.register(
          name: name!.trim(),
          email: email.trim(),
          password: password,
        );
      }
      if (ref.mounted) {
        state = const AuthFormState(status: AuthFormStatus.succeeded);
      }
    } catch (error) {
      if (ref.mounted) {
        state = AuthFormState(
          status: AuthFormStatus.failed,
          error: error is SessionException
              ? error.message
              : 'Unable to save your session securely. Please try again.',
        );
      }
    }
  }
}
