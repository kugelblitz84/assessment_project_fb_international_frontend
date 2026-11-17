import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/validators.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_form_state.dart';
import 'package:assessment_project_fb_international_frontend/features/auth/model/auth_validation.dart';

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
        AuthValidation.password(password) ??
        (mode == AuthFormMode.register ? AuthValidation.name(name) : null);
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
          error: ApiErrorMessages.messageFor(ApiErrorHandler.codeFor(error)),
        );
      }
    }
  }
}
