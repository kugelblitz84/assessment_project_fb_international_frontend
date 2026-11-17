import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:assessment_project_fb_international_frontend/core/network/cookie_transport.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';

import 'package:assessment_project_fb_international_frontend/core/session/application/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/session_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  late MemoryTokenStorage storage;
  late StubAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    storage = MemoryTokenStorage();
    repository = StubAuthRepository();
    container = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  test('startup without a token is unauthenticated', () async {
    expect(container.read(currentUserProvider), isNull);
    expect(
      await container.read(sessionProvider.future),
      isA<Unauthenticated>(),
    );
    expect(repository.restoredToken, isNull);
    expect(repository.refreshCalls, 0);
  });

  test('browser-style restoration probes invisible refresh cookies', () async {
    final browser = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
        cookieTransportProvider.overrideWithValue(_BrowserCookies()),
      ],
    );
    repository.refreshToken = 'cookie-restored';
    expect(await browser.read(sessionProvider.future), isA<Authenticated>());
    expect(repository.refreshCalls, 1);
    expect(repository.restoredToken, 'cookie-restored');
  });

  test('rejected browser refresh enters guest mode', () async {
    final browser = ProviderContainer.test(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repository),
        cookieTransportProvider.overrideWithValue(_BrowserCookies()),
      ],
    );
    expect(await browser.read(sessionProvider.future), isA<Unauthenticated>());
    expect(repository.refreshCalls, 1);
    expect(browser.read(tokenRefreshCoordinatorProvider).enabled, isFalse);
  });

  test(
    'startup restores the saved token and derives the current user',
    () async {
      storage.token = 'saved-token';
      expect(
        await container.read(sessionProvider.future),
        isA<Authenticated>(),
      );
      expect(repository.restoredToken, 'saved-token');
      expect(container.read(currentUserProvider), same(testUser));
    },
  );

  test('an invalid session clears its saved token', () async {
    storage.token = 'expired-token';
    repository.currentUserError = const InvalidSessionException();
    expect(
      await container.read(sessionProvider.future),
      isA<Unauthenticated>(),
    );
    expect(storage.token, isNull);
    expect(container.read(currentUserProvider), isNull);
  });

  test(
    'a startup network failure preserves the token and can be retried',
    () async {
      storage.token = 'saved-token';
      repository.currentUserError = const AuthRequestException(
        'Server unavailable',
      );
      await expectLater(
        container.read(sessionProvider.future),
        throwsA(isA<AuthRequestException>()),
      );
      expect(container.read(sessionProvider).hasError, isTrue);
      expect(container.read(currentUserProvider), isNull);
      expect(storage.token, 'saved-token');
      repository.currentUserError = null;
      container.invalidate(sessionProvider);
      expect(
        await container.read(sessionProvider.future),
        isA<Authenticated>(),
      );
    },
  );

  test('secure storage read failures are surfaced during startup', () async {
    storage.readError = StateError('Storage unavailable');
    await expectLater(
      container.read(sessionProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(container.read(sessionProvider).hasError, isTrue);
  });

  for (final register in [false, true]) {
    test(
      '${register ? 'register' : 'login'} waits for token persistence without global loading',
      () async {
        await container.read(sessionProvider.future);
        storage.saveGate = Completer<void>();
        final controller = container.read(sessionProvider.notifier);
        final operation = register
            ? controller.register(
                name: 'Test Customer',
                email: testUser.email,
                password: 'password',
              )
            : controller.login(email: testUser.email, password: 'password');
        await storage.saving.future;
        expect(container.read(sessionProvider).isLoading, isFalse);
        expect(
          container.read(sessionProvider).asData?.value,
          isA<Unauthenticated>(),
        );
        expect(container.read(currentUserProvider), isNull);
        storage.saveGate!.complete();
        await operation;
        expect(storage.token, 'test-access-token');
        expect(container.read(currentUserProvider), same(testUser));
      },
    );
  }

  test(
    'credential and persistence failures propagate without authenticating',
    () async {
      await container.read(sessionProvider.future);
      final controller = container.read(sessionProvider.notifier);
      repository.authError = const InvalidCredentialsException();
      await expectLater(
        controller.login(email: testUser.email, password: 'incorrect'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      repository.authError = null;
      storage.saveError = StateError('Storage unavailable');
      await expectLater(
        controller.register(
          name: 'Test',
          email: testUser.email,
          password: 'password',
        ),
        throwsA(isA<StateError>()),
      );
      expect(storage.token, isNull);
      expect(
        container.read(sessionProvider).asData?.value,
        isA<Unauthenticated>(),
      );
    },
  );

  test(
    'logout drains authentication token persistence before clearing credentials',
    () async {
      await container.read(sessionProvider.future);
      storage.saveGate = Completer<void>();
      final controller = container.read(sessionProvider.notifier);
      final login = controller.login(
        email: testUser.email,
        password: 'password',
      );
      await storage.saving.future;
      var finishedLogout = false;
      final logout = controller.logout().then((_) => finishedLogout = true);
      await Future<void>.delayed(Duration.zero);
      expect(finishedLogout, isFalse);
      storage.saveGate!.complete();
      await Future.wait([login, logout]);
      expect(storage.token, isNull);
      expect(container.read(currentUserProvider), isNull);
    },
  );

  test(
    'account replacement clears the prior user and waits for older token writes',
    () async {
      storage.token = 'saved';
      await container.read(sessionProvider.future);
      storage.saveGate = Completer<void>();
      final controller = container.read(sessionProvider.notifier);
      final first = controller.login(
        email: testUser.email,
        password: 'password',
      );
      await storage.saving.future;
      expect(container.read(currentUserProvider), isNull);
      const replacementUser = UserEntity(
        id: 'customer-2',
        name: 'Replacement',
        email: 'new@example.com',
      );
      repository.authenticationSession = const AuthSession(
        accessToken: 'replacement-token',
        user: replacementUser,
      );
      final replacement = controller.register(
        name: 'Replacement',
        email: 'new@example.com',
        password: 'password',
      );
      await Future<void>.delayed(Duration.zero);
      storage.saveGate!.complete();
      await Future.wait([first, replacement]);
      expect(storage.token, 'replacement-token');
      expect(container.read(currentUserProvider), same(replacementUser));
    },
  );

  test(
    'logout propagates deletion failures and clears the user only on success',
    () async {
      storage.token = 'saved-token';
      await container.read(sessionProvider.future);
      storage.clearError = StateError('Storage unavailable');
      final controller = container.read(sessionProvider.notifier);
      await expectLater(controller.logout(), throwsA(isA<StateError>()));
      expect(container.read(currentUserProvider), same(testUser));
      expect(storage.token, 'saved-token');
      storage.clearError = null;
      await controller.logout();
      expect(storage.token, isNull);
      expect(container.read(currentUserProvider), isNull);
      expect(
        container.read(sessionProvider).asData?.value,
        isA<Unauthenticated>(),
      );
    },
  );
}

/// Models the browser's inability to inspect HttpOnly cookies.
class _BrowserCookies extends CookieTransport {
  _BrowserCookies() : super(Uri.parse('https://api.example.test'));
  @override
  Future<bool> canRestoreSession() async => true;
  @override
  Future<void> clear() async {}
}
