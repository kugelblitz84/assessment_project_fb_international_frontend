import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_session.dart';
import '../domain/auth_state.dart';
import '../domain/session_exception.dart';
import 'session_providers.dart';
import '../../network/dio_provider.dart';

final sessionProvider = AsyncNotifierProvider<SessionController, AuthState>(
  SessionController.new,
  // Startup errors are retried explicitly from the bootstrap error page.
  retry: (retryCount, error) => null,
);

class SessionController extends AsyncNotifier<AuthState> {
  int _operation = 0;
  Future<AuthSession>? _pendingAuthentication;
  @override
  Future<AuthState> build() async {
    final operation = _operation;
    final storage = ref.watch(tokenStorageProvider);
    final repository = ref.watch(authRepositoryProvider);
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    coordinator.onInvalidSession = () {
      if (ref.mounted) state = const AsyncData(Unauthenticated());
    };
    final token = await storage.readToken();
    try {
      final activeToken = token == null || token.isEmpty
          ? await repository.refresh()
          : token;
      final user = await repository.getCurrentUser(token: activeToken);
      if (operation != _operation) return const Unauthenticated();
      return Authenticated(user: user);
    } on InvalidSessionException {
      if (operation != _operation) return const Unauthenticated();
      coordinator.invalidate();
      await coordinator.drain();
      await storage.clearToken();
      await ref.read(cookieTransportProvider).clear();
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
    final operation = ++_operation;
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    coordinator.invalidate();
    await coordinator.drain();
    try {
      await _pendingAuthentication;
    } catch (_) {}
    if (operation != _operation) return;
    coordinator.enabled = true;
    final pending = authenticate();
    _pendingAuthentication = pending;
    final session = await pending;
    if (operation != _operation) return;
    await storage.saveToken(session.accessToken);
    if (operation != _operation) {
      await storage.clearToken();
      return;
    }
    if (ref.mounted) state = AsyncData(Authenticated(user: session.user));
  }

  Future<void> logout() async {
    ++_operation;
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    coordinator.invalidate();
    await coordinator.drain();
    try {
      await _pendingAuthentication;
    } catch (_) {}
    final storage = ref.read(tokenStorageProvider);
    Object? failure;
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      failure = const AuthRequestException(
        'Logged out locally. Server revocation could not be confirmed.',
      );
    }
    await storage.clearToken();
    await ref.read(cookieTransportProvider).clear();
    if (ref.mounted) {
      state = AsyncData(Unauthenticated(message: failure?.toString()));
    }
  }
}
