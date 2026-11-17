import './user_entity.dart';

sealed class AuthState {
  const AuthState();
}

class Authenticated extends AuthState {
  const Authenticated({required this.user});
  final UserEntity user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.message, this.didLogout = false});
  final String? message;
  final bool didLogout;
}
