enum AuthFormMode { login, register }

enum AuthFormStatus { idle, submitting, succeeded, failed }

class AuthFormState {
  const AuthFormState({this.status = AuthFormStatus.idle, this.error});
  final AuthFormStatus status;
  final String? error;
  bool get submitting => status == AuthFormStatus.submitting;
}
