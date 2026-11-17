import './user_entity.dart';

sealed class AuthState {
  const AuthState();
}

class Authenticated extends AuthState {
  const Authenticated({required this.user, this.generation = 0});
  final UserEntity user;
  final int generation;
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});
  final String? message;
}
