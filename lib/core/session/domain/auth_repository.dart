import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';

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
