import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/session/application/token_refresh_coordinator.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';

import 'support/session_fakes.dart';

void main() {
  test(
    'concurrent refresh and late failures share the renewed token',
    () async {
      final storage = MemoryTokenStorage('old');
      final gate = Completer<String>();
      var calls = 0;
      final coordinator = TokenRefreshCoordinator(storage, () {
        calls++;
        return gate.future;
      }, () async {});
      final requests = List.generate(
        10,
        (_) => coordinator.refresh(failedToken: 'old'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      gate.complete('new');
      expect(await Future.wait(requests), everyElement('new'));
      expect(await coordinator.refresh(failedToken: 'old'), 'new');
      expect(calls, 1);
    },
  );
  test(
    'invalid session clears credentials but temporary failures preserve them',
    () async {
      final storage = MemoryTokenStorage('old');
      var cleared = false;
      final coordinator = TokenRefreshCoordinator(
        storage,
        () async => throw const InvalidSessionException(),
        () async {
          cleared = true;
        },
      );
      await expectLater(
        coordinator.refresh(),
        throwsA(isA<InvalidSessionException>()),
      );
      expect(storage.token, isNull);
      expect(cleared, true);
      storage.token = 'saved';
      final offline = TokenRefreshCoordinator(
        storage,
        () async => throw const AuthRequestException('Offline'),
        () async {},
      );
      await expectLater(
        offline.refresh(),
        throwsA(isA<AuthRequestException>()),
      );
      expect(storage.token, 'saved');
    },
  );
  test('pending refresh cannot save a token after logout', () async {
    final storage = MemoryTokenStorage('old');
    final gate = Completer<String>();
    final coordinator = TokenRefreshCoordinator(
      storage,
      () => gate.future,
      () async {},
    );
    final operation = coordinator.refresh();
    final assertion = expectLater(
      operation,
      throwsA(isA<InvalidSessionException>()),
    );
    await Future<void>.delayed(Duration.zero);
    coordinator.invalidate();
    gate.complete('new');
    await assertion;
    expect(storage.token, 'old');
  });
}
