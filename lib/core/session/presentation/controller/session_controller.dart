import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';

final sessionProvider = AsyncNotifierProvider<SessionController, AuthState>(
  SessionController.new,
  // Restoration failures allow guest access; retry is explicit from Profile.
  retry: (retryCount, error) => null,
);

class SessionController extends AsyncNotifier<AuthState> {
  int _operation = 0;
  // Login, registration and logout share one credential-write queue.
  Future<void>? _pendingCredentials;
  @override
  Future<AuthState> build() async {
    final operation = _operation;
    final storage = ref.watch(tokenStorageProvider);
    final repository = ref.watch(authRepositoryProvider);
    final cookies = ref.watch(cookieTransportProvider);
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    void invalidSession() {
      if (ref.mounted) state = const AsyncData(Unauthenticated());
    }

    coordinator.onInvalidSession = invalidSession;
    ref.onDispose(() {
      if (identical(coordinator.onInvalidSession, invalidSession)) {
        coordinator.onInvalidSession = null;
      }
    });
    try {
      final blocked = await cookies.restorationBlocked();
      if (!ref.mounted || operation != _operation) return _settledSession();
      if (blocked) {
        coordinator.invalidate();
        return const Unauthenticated();
      }
      final token = await storage.readToken();
      if (!ref.mounted || operation != _operation) return _settledSession();
      if ((token == null || token.isEmpty) &&
          !await cookies.canRestoreSession()) {
        if (!ref.mounted || operation != _operation) return _settledSession();
        coordinator.invalidate();
        return const Unauthenticated();
      }
      if (!ref.mounted || operation != _operation) return _settledSession();
      coordinator.enable();
      final activeToken = token == null || token.isEmpty
          ? await repository.refresh()
          : token;
      if (!ref.mounted || operation != _operation) return _settledSession();
      final user = await repository.getCurrentUser(token: activeToken);
      if (!ref.mounted || operation != _operation) return _settledSession();
      return Authenticated(user: user, generation: operation);
    } on InvalidSessionException {
      if (!ref.mounted || operation != _operation) return _settledSession();
      coordinator.invalidate();
      // Cleanup joins the credential queue so a later login cannot race an old
      // storage/cookie deletion that has already started.
      final cleanup = () async {
        await coordinator.drain();
        if (!ref.mounted || operation != _operation) return;
        try {
          await storage.clearToken();
        } finally {
          await cookies.clear();
        }
      }();
      await _trackCredentials(cleanup);
      return _settledSession();
    } catch (_) {
      if (!ref.mounted || operation != _operation) return _settledSession();
      coordinator.invalidate();
      rethrow;
    }
    // Transient failures retain credentials; protected requests remain disabled.
  }

  AuthState _settledSession() => ref.mounted
      ? state.asData?.value ?? const Unauthenticated()
      : const Unauthenticated();

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
      _pendingCredentials,
    );
    return _trackCredentials(pending);
  }

  Future<void> _trackCredentials(Future<void> operation) {
    late final Future<void> pending;
    pending = operation.whenComplete(() {
      if (identical(_pendingCredentials, pending)) _pendingCredentials = null;
    });
    _pendingCredentials = pending;
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
    if (!ref.mounted || operation != _operation) return;
    await storage.clearToken();
    await ref.read(cookieTransportProvider).clear();
    if (ref.mounted) state = const AsyncData(Unauthenticated());
    coordinator.enable();
    try {
      final session = await authenticate();
      if (operation != _operation) return;
      await storage.saveToken(session.accessToken);
      if (operation != _operation) {
        await storage.clearToken();
        return;
      }
      await ref.read(cookieTransportProvider).allowRestoration();
      if (!ref.mounted || operation != _operation) return;
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

  Future<void> logout() {
    final operation = ++_operation;
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    coordinator.invalidate();
    state = const AsyncData(Unauthenticated());
    final pending = _performLogout(operation, _pendingCredentials);
    return _trackCredentials(pending);
  }

  Future<void> _performLogout(int operation, Future<void>? previous) async {
    final coordinator = ref.read(tokenRefreshCoordinatorProvider);
    final repository = ref.read(authRepositoryProvider);
    final cookies = ref.read(cookieTransportProvider);
    final storage = ref.read(tokenStorageProvider);
    Object? localFailure;
    StackTrace? localStack;
    Future<void> cleanup(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stack) {
        localFailure ??= error;
        localStack ??= stack;
      }
    }

    await cleanup(cookies.blockRestoration);
    await coordinator.drain();
    try {
      await previous;
    } catch (_) {}
    await cleanup(cookies.blockRestoration);
    String? notice;
    try {
      await repository.logout();
    } catch (_) {
      notice =
          'Signed out in this app. Server revocation could not be confirmed. Sign in explicitly to reconnect.';
    }
    // Attempt every local cleanup even when one storage backend fails. Only the
    // server can remove browser HttpOnly cookies; the local flag records intent.
    await cleanup(storage.clearToken);
    await cleanup(cookies.clear);
    if (ref.mounted && operation == _operation) {
      state = AsyncData(
        Unauthenticated(
          message: localFailure == null
              ? notice
              : 'Unable to clear all saved session data. Retry signing out before reloading.',
        ),
      );
    }
    if (localFailure != null) {
      Error.throwWithStackTrace(localFailure!, localStack!);
    }
  }
}
