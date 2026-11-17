import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/config/api_config.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/token_storage_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';

import 'support/session_fakes.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, int status, {String? cookie}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
        if (cookie != null) 'set-cookie': [cookie],
      },
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('fresh native startup sends no backend requests', () async {
    final container = ProviderContainer.test(
      overrides: [tokenStorageProvider.overrideWithValue(MemoryTokenStorage())],
    );
    var requests = 0;
    final adapter = Adapter((_) async {
      requests++;
      return jsonResponse({}, 401);
    });
    container.read(authTransportProvider).httpClientAdapter = adapter;
    container.read(dioProvider).httpClientAdapter = adapter;
    expect(
      await container.read(sessionProvider.future),
      isA<Unauthenticated>(),
    );
    expect(requests, 0);
  });

  test(
    'native startup restores a persisted refresh cookie without an access token',
    () async {
      final storage = MemoryTokenStorage();
      ProviderContainer createContainer() => ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          apiBaseUrlProvider.overrideWithValue('https://api.example.test'),
        ],
      );
      final first = createContainer();
      first.read(dioProvider).httpClientAdapter = Adapter(
        (_) async => jsonResponse(
          {},
          200,
          cookie: 'refresh=saved; HttpOnly; Secure; Path=/auth; Max-Age=3600',
        ),
      );
      await first.read(dioProvider).post('/auth/login');
      first.dispose();
      final next = createContainer();
      addTearDown(next.dispose);
      var refreshes = 0;
      next.read(authTransportProvider).httpClientAdapter = Adapter((
        request,
      ) async {
        refreshes++;
        expect(request.path, '/auth/refresh');
        expect(
          request.headers['cookie'] ?? request.headers['Cookie'],
          contains('refresh=saved'),
        );
        return jsonResponse({'accessToken': 'restored'}, 200);
      });
      next.read(dioProvider).httpClientAdapter = Adapter((request) async {
        expect(request.path, '/auth/me');
        expect(request.headers['Authorization'], 'Bearer restored');
        return jsonResponse({
          'user': {
            'id': 'customer-1',
            'name': 'Test Customer',
            'email': 'customer@example.com',
          },
        }, 200);
      });
      expect(await next.read(sessionProvider.future), isA<Authenticated>());
      expect(refreshes, 1);
      expect(storage.token, 'restored');
    },
  );

  for (final expire in [false, true]) {
    test(
      'public API works after ${expire ? 'session expiry' : 'logout'} without refreshing guests',
      () async {
        final storage = MemoryTokenStorage('saved');
        final container = ProviderContainer.test(
          overrides: [tokenStorageProvider.overrideWithValue(storage)],
        );
        final dio = container.read(dioProvider);
        var protectedRequests = 0;
        var publicStatus = 200;
        dio.httpClientAdapter = Adapter((request) async {
          if (request.path == '/auth/me') {
            return jsonResponse({
              'user': {
                'id': 'customer-1',
                'name': 'Test Customer',
                'email': 'customer@example.com',
              },
            }, 200);
          }
          if (request.path == '/services') {
            expect(request.headers['Authorization'], isNull);
            return jsonResponse({}, publicStatus);
          }
          protectedRequests++;
          return jsonResponse({}, 401);
        });
        var refreshes = 0;
        container.read(authTransportProvider).httpClientAdapter = Adapter((
          request,
        ) async {
          if (request.path == '/auth/refresh') refreshes++;
          return jsonResponse({}, request.path == '/auth/refresh' ? 401 : 204);
        });
        await container.read(sessionProvider.future);
        if (expire) {
          await expectLater(
            dio.get('/protected'),
            throwsA(isA<DioException>()),
          );
        } else {
          await container.read(sessionProvider.notifier).logout();
        }
        expect(container.read(currentUserProvider), isNull);
        expect(storage.token, isNull);
        expect(
          container.read(sessionProvider).asData?.value,
          isA<Unauthenticated>(),
        );
        final before = protectedRequests;
        await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));
        expect(protectedRequests, before);
        final publicOptions = Options(
          extra: {requestAccessKey: RequestAccess.public},
          headers: {'Authorization': 'Bearer stale'},
        );
        await dio.get('/services', options: publicOptions);
        publicStatus = 401;
        await expectLater(
          dio.get('/services', options: publicOptions),
          throwsA(isA<DioException>()),
        );
        expect(refreshes, expire ? 1 : 0);
      },
    );
  }
  test(
    'cookies persist, rotate, refresh once and stay off external requests',
    () async {
      final storage = MemoryTokenStorage('old');
      ProviderContainer container() => ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          apiBaseUrlProvider.overrideWithValue('https://api.example.test'),
        ],
      );
      final first = container();
      first.read(dioProvider).httpClientAdapter = Adapter(
        (request) async => jsonResponse(
          {},
          200,
          cookie: 'refresh=first; HttpOnly; Secure; Path=/auth; Max-Age=3600',
        ),
      );
      await first.read(dioProvider).post('/auth/login');
      first.dispose();
      final next = container();
      addTearDown(next.dispose);
      var refreshes = 0;
      next.read(authTransportProvider).httpClientAdapter = Adapter((
        request,
      ) async {
        refreshes++;
        expect(request.path, '/auth/refresh');
        expect(request.headers['Authorization'], isNull);
        expect(
          request.headers['cookie'] ?? request.headers['Cookie'],
          contains('refresh=first'),
        );
        return jsonResponse(
          {'accessToken': 'new'},
          200,
          cookie: 'refresh=second; HttpOnly; Secure; Path=/auth; Max-Age=3600',
        );
      });
      next.read(dioProvider).httpClientAdapter = Adapter((request) async {
        if (request.uri.host == 'external.test') {
          expect(request.headers['Authorization'], isNull);
          expect(request.headers['cookie'], isNull);
          return jsonResponse({}, 200);
        }
        if (request.path == '/auth/logout') {
          expect(
            request.headers['cookie'] ?? request.headers['Cookie'],
            contains('refresh=second'),
          );
          return jsonResponse({}, 200);
        }
        return jsonResponse(
          {},
          request.headers['Authorization'] == 'Bearer new' ? 200 : 401,
        );
      });
      await Future.wait(
        List.generate(5, (_) => next.read(dioProvider).get('/protected')),
      );
      expect(refreshes, 1);
      expect(storage.token, 'new');
      await next.read(dioProvider).post('/auth/logout');
      await next.read(dioProvider).get('https://external.test/resource');
    },
  );
  test('a second 401 is returned without another refresh', () async {
    final storage = MemoryTokenStorage('old');
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    var calls = 0;
    container.read(authTransportProvider).httpClientAdapter = Adapter((
      _,
    ) async {
      calls++;
      return jsonResponse({'accessToken': 'new'}, 200);
    });
    container.read(dioProvider).httpClientAdapter = Adapter(
      (_) async => jsonResponse({}, 401),
    );
    await expectLater(
      container.read(dioProvider).get('/protected'),
      throwsA(isA<DioException>()),
    );
    expect(calls, 1);
  });
}
