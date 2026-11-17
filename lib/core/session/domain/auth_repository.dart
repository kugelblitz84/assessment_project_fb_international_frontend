import 'auth_session.dart';
import 'user_entity.dart';

abstract interface class AuthRepository {
  Future<String> refresh();
  Future<void> logout();
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserEntity> getCurrentUser({required String token});
}
