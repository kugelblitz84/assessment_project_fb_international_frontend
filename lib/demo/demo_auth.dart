import 'package:dio/dio.dart';
import '../core/network/cookie_transport.dart';
import '../core/session/domain/auth_repository.dart';
import '../core/session/domain/auth_session.dart';
import '../core/session/domain/token_storage.dart';
import '../core/session/domain/user_entity.dart';

/// These adapters are wired ONLY by main_demo.dart, never the normal app.
class DemoTokenStorage implements TokenStorage {
  String? token;
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> saveToken(String value) async {
    token = value;
  }

  @override
  Future<void> clearToken() async {
    token = null;
  }
}

class DemoCookieTransport extends CookieTransport {
  DemoCookieTransport() : super(Uri.parse('https://demo.invalid'));
  @override
  Future<bool> canRestoreSession() async => false;
  @override
  void configure(Dio dio, bool Function(Uri) trusted) {}
  @override
  Future<void> clear() async {}
}

class DemoAuthRepository implements AuthRepository {
  UserEntity _user = const UserEntity(
    id: 'demo-driver',
    name: 'Demo Driver',
    email: 'driver@autocare.demo',
  );
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _user = UserEntity(
      id: email.trim().toLowerCase(),
      name: _user.email == email ? _user.name : 'Demo Driver',
      email: email,
    );
    return AuthSession(accessToken: 'demo-token', user: _user);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _user = UserEntity(
      id: email.trim().toLowerCase(),
      name: name,
      email: email,
    );
    return AuthSession(accessToken: 'demo-token', user: _user);
  }

  @override
  Future<UserEntity> getCurrentUser({required String token}) async => _user;
  @override
  Future<String> refresh() async => 'demo-token';
  @override
  Future<void> logout() async {}
}
