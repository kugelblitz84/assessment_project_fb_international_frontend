import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/token_storage_provider.dart';
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
