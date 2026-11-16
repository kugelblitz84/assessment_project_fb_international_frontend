import './user_entity.dart';

abstract interface class AuthRepository {
  Future<String?> readToken();

  Future<void> saveToken(String token);

  Future<void> clearSession();

  Future<UserEntity> getCurrentUser({required String token});
}
