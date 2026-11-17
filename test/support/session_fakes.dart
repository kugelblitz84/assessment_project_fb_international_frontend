import 'dart:async';

import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_repository.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/token_storage.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';

const testUser = UserEntity(
  id: 'customer-1',
  name: 'Test Customer',
  email: 'customer@example.com',
);

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);

  String? token;
  Object? readError;
  Object? saveError;
  Object? clearError;
  Completer<void>? saveGate;
  final saving = Completer<void>();
  int reads = 0;

  @override
  Future<String?> readToken() async {
    reads++;
    if (readError != null) throw readError!;
    return token;
  }

  @override
  Future<void> saveToken(String value) async {
    if (!saving.isCompleted) saving.complete();
    if (saveGate != null) await saveGate!.future;
    if (saveError != null) throw saveError!;
    token = value;
  }

  @override
  Future<void> clearToken() async {
    if (clearError != null) throw clearError!;
    token = null;
  }
}

class StubAuthRepository implements AuthRepository {
  Completer<void>? logoutGate;
  final logoutStarted = Completer<void>();
  Object? logoutError;
  int loginCalls = 0;
  int refreshCalls = 0;
  String? refreshToken;
  Object? refreshError;
  @override
  Future<String> refresh() async {
    refreshCalls++;
    if (refreshError != null) throw refreshError!;
    return refreshToken ?? (throw const InvalidSessionException());
  }

  @override
  Future<void> logout() async {
    if (!logoutStarted.isCompleted) logoutStarted.complete();
    if (logoutGate != null) await logoutGate!.future;
    if (logoutError != null) throw logoutError!;
  }

  Object? currentUserError;
  Object? authError;
  String? restoredToken;
  Completer<UserEntity>? currentUserGate;
  Completer<AuthSession>? authGate;
  AuthSession authenticationSession = const AuthSession(
    accessToken: 'test-access-token',
    user: testUser,
  );

  @override
  Future<UserEntity> getCurrentUser({required String token}) async {
    restoredToken = token;
    if (currentUserError != null) throw currentUserError!;
    return currentUserGate == null ? testUser : currentUserGate!.future;
  }

  Future<AuthSession> _authenticate() async {
    if (authError != null) throw authError!;
    return authGate == null ? authenticationSession : authGate!.future;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    loginCalls++;
    return _authenticate();
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate();
}
