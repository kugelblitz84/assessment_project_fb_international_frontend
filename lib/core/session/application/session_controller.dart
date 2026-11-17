import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_session.dart';
import '../domain/auth_state.dart';
import '../domain/session_exception.dart';
import '../domain/user_entity.dart';
import 'session_providers.dart';
import '../../network/dio_provider.dart';

final sessionProvider = AsyncNotifierProvider<SessionController, AuthState>(
  SessionController.new,
  // Restoration failures allow guest access; retry is explicit from Profile.
  retry: (retryCount, error) => null,
);

class SessionController extends AsyncNotifier<AuthState> {
  int _operation = 0;
  Future<void>? _pendingAuthentication;
  @override
  Future<AuthState> build() async {
    final operation = _operation;
    final storage = ref.watch(tokenStorageProvider);
    final repository = ref.watch(authRepositoryProvider);
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    coordinator.onInvalidSession = () {
      if (ref.mounted) state = const AsyncData(Unauthenticated());
    };
    try {
      final token = await storage.readToken();
      if ((token == null || token.isEmpty) &&
          !await ref.read(cookieTransportProvider).canRestoreSession()) {
        coordinator.invalidate();
        return const Unauthenticated();
      }
      coordinator.enabled = true;
      final activeToken = token == null || token.isEmpty
          ? await repository.refresh()
          : token;
      final user = await repository.getCurrentUser(token: activeToken);
      if (operation != _operation) return const Unauthenticated();
      return Authenticated(user: user, generation: operation);
    } on InvalidSessionException {
      if (operation != _operation) return const Unauthenticated();
      coordinator.invalidate();
      await coordinator.drain();
      await storage.clearToken();
      await ref.read(cookieTransportProvider).clear();
      return const Unauthenticated();
    } catch (_) {
      coordinator.invalidate();
      rethrow;
    }
    // Other failures retain credentials, but protected calls stay disabled.
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

  /// Accept a profile response only for the currently authenticated account.
  /// Credentials, refresh coordination and session ownership remain unchanged.
  void updateUser(UserEntity user) {
    final current = state.asData?.value;
    if (current is Authenticated && current.user.id == user.id) {
      state = AsyncData(
        Authenticated(user: user, generation: current.generation),
      );
    }
  }

  Future<void> _authenticate(Future<AuthSession> Function() authenticate) {
    final operation = ++_operation;
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    coordinator.invalidate();
    final pending = _performAuthentication(
      authenticate,
      operation,
      _pendingAuthentication,
    );
    _pendingAuthentication = pending;
    return pending;
  }

  Future<void> _performAuthentication(
    Future<AuthSession> Function() authenticate,
    int operation,
    Future<void>? previous,
  ) async {
    final storage = ref.read(tokenStorageProvider);
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    await coordinator.drain();
    try {
      await previous;
    } catch (_) {}
    if (operation != _operation) return;
    await storage.clearToken();
    await ref.read(cookieTransportProvider).clear();
    if (ref.mounted) state = const AsyncData(Unauthenticated());
    coordinator.enabled = true;
    try {
      final session = await authenticate();
      if (operation != _operation) return;
      await storage.saveToken(session.accessToken);
      if (operation != _operation) {
        await storage.clearToken();
        return;
      }
      if (ref.mounted) {
        state = AsyncData(
          Authenticated(user: session.user, generation: operation),
        );
      }
    } catch (_) {
      if (operation == _operation) {
        coordinator.invalidate();
        await storage.clearToken();
        await ref.read(cookieTransportProvider).clear();
      }
      rethrow;
    }
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
