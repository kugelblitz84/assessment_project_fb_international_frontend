import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_session.dart';
import '../domain/auth_state.dart';
import '../domain/session_exception.dart';
import 'session_providers.dart';

final sessionProvider = AsyncNotifierProvider<SessionController, AuthState>(
  SessionController.new,
  // Startup errors are retried explicitly from the bootstrap error page.
  retry: (retryCount, error) => null,
);

class SessionController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.watch(tokenStorageProvider);
    final repository = ref.watch(authRepositoryProvider);
    final token = await storage.readToken();
    if (token == null || token.isEmpty) return const Unauthenticated();

    try {
      final user = await repository.getCurrentUser(token: token);
      return Authenticated(user: user);
    } on InvalidSessionException {
      await storage.clearToken();
      return const Unauthenticated();
    }
    // Other failures become AsyncError without deleting a potentially valid token.
  }

  Future<void> login({required String email, required String password}) =>
      _authenticate(
        () => ref
            .read(authRepositoryProvider)
            .login(email: email, password: password),
      );

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate(
    () => ref
        .read(authRepositoryProvider)
        .register(name: name, email: email, password: password),
  );

  Future<void> _authenticate(
    Future<AuthSession> Function() authenticate,
  ) async {
    final storage = ref.read(tokenStorageProvider);
    final session = await authenticate();
    await storage.saveToken(session.accessToken);
    if (ref.mounted) state = AsyncData(Authenticated(user: session.user));
  }

  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    await storage.clearToken();
    if (ref.mounted) state = const AsyncData(Unauthenticated());
  }
}
