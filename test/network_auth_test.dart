import 'dart:convert';
import 'dart:typed_data';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/auth_repository_impl.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/secure_token_storage.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/user_model.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/session_fakes.dart';

const _userJson = {
  'id': 'customer-1',
  'name': 'Test Customer',
  'email': 'customer@example.com',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('secure storage round trips and deletes the access token', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = SecureTokenStorage(FlutterSecureStorage());
    expect(await storage.readToken(), isNull);
    await storage.saveToken('test-token');
    expect(await storage.readToken(), 'test-token');
    await storage.clearToken();
    expect(await storage.readToken(), isNull);
  });

  test('user JSON validates required strings and supports copyWith', () {
    final user = UserModel.fromJson(_userJson);
    expect(user.copyWith(name: 'Updated').name, 'Updated');
    expect(user.name, 'Test Customer');
    for (final field in ['id', 'name', 'email']) {
      for (final invalid in [null, '', ' ', 42]) {
        expect(
          () => UserModel.fromJson({..._userJson, field: invalid}),
          throwsA(isA<InvalidAuthResponseException>()),
        );
      }
    }
  });

  group('Dio authentication', () {
    late MemoryTokenStorage storage;
    late Dio dio;
    late AuthRepositoryImpl repository;
    late _ResponseAdapter adapter;

    setUp(() {
      storage = MemoryTokenStorage('saved-token');
      final container = ProviderContainer.test(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          apiBaseUrlProvider.overrideWithValue('http://localhost:3000/api'),
        ],
      );
      dio = container.read(dioProvider);
      adapter = _ResponseAdapter();
      dio.httpClientAdapter = adapter;
      container.read(authTransportProvider).httpClientAdapter = adapter;
      repository = AuthRepositoryImpl(dio);
    });

    test(
      'login, register and current user follow the defined contract',
      () async {
        adapter.body = {'accessToken': 'returned-token', 'user': _userJson};
        final login = await repository.login(
          email: testUser.email,
          password: 'secret',
        );
        expect(login.accessToken, 'returned-token');
        expect(login.user.id, testUser.id);
        expect(adapter.last!.method, 'POST');
        expect(adapter.last!.uri.path, '/api${ApiEndpoints.login}');
        expect(adapter.last!.data, {
          'email': testUser.email,
          'password': 'secret',
        });
        expect(adapter.last!.headers['Authorization'], isNull);
        await repository.register(
          name: testUser.name,
          email: testUser.email,
          password: 'secret',
        );
        expect(adapter.last!.uri.path, '/api${ApiEndpoints.register}');
        expect(adapter.last!.data, {
          'name': testUser.name,
          'email': testUser.email,
          'password': 'secret',
        });
        expect(adapter.last!.headers['Authorization'], isNull);
        adapter.body = {'user': _userJson};
        final user = await repository.getCurrentUser(
          token: 'explicit-startup-token',
        );
        expect(user.email, testUser.email);
        expect(adapter.last!.method, 'GET');
        expect(adapter.last!.uri.path, '/api${ApiEndpoints.currentUser}');
        expect(
          adapter.last!.headers['Authorization'],
          'Bearer explicit-startup-token',
        );
        expect(storage.reads, 0);
      },
    );

    test(
      'bearer tokens stay on the backend and skip public auth endpoints',
      () async {
        await dio.get<Object?>('/protected');
        expect(adapter.last!.headers['Authorization'], 'Bearer saved-token');
        expect(adapter.last!.followRedirects, isFalse);
        for (final destination in [
          'https://external.example/resource',
          'http://localhost:4000/api/protected',
          'https://localhost:3000/api/protected',
          'http://localhost:3000/unrelated',
          ApiEndpoints.login,
          ApiEndpoints.register,
          '${ApiEndpoints.login}/',
          '${ApiEndpoints.register}/',
        ]) {
          await dio.get<Object?>(
            destination,
            options: Options(headers: {'Authorization': 'Bearer stale-token'}),
          );
          expect(
            adapter.last!.headers['Authorization'],
            isNull,
            reason: destination,
          );
        }
        expect(storage.reads, 1);
      },
    );

    test(
      '401 distinguishes credentials from an invalid startup session',
      () async {
        adapter.status = 401;
        await expectLater(
          repository.login(email: testUser.email, password: 'incorrect'),
          throwsA(isA<InvalidCredentialsException>()),
        );
        await expectLater(
          repository.getCurrentUser(token: 'expired-token'),
          throwsA(isA<InvalidSessionException>()),
        );
      },
    );

    test(
      'server, network and malformed responses become safe domain errors',
      () async {
        adapter.status = 503;
        await expectLater(
          repository.getCurrentUser(token: 'saved-token'),
          throwsA(isA<AuthRequestException>()),
        );
        adapter.status = 200;
        adapter.failure = DioExceptionType.connectionError;
        await expectLater(
          repository.getCurrentUser(token: 'saved-token'),
          throwsA(isA<AuthRequestException>()),
        );
        adapter.failure = null;
        for (final body in [
          null,
          [],
          {'user': _userJson},
          {'accessToken': '', 'user': _userJson},
          {'accessToken': 'token', 'user': {}},
        ]) {
          adapter.body = body;
          await expectLater(
            repository.login(email: testUser.email, password: 'secret'),
            throwsA(isA<InvalidAuthResponseException>()),
          );
        }
        adapter.body = {
          'user': {'id': 123},
        };
        await expectLater(
          repository.getCurrentUser(token: 'saved-token'),
          throwsA(isA<InvalidAuthResponseException>()),
        );
      },
    );
  });
}

class _ResponseAdapter implements HttpClientAdapter {
  Object? body = <String, Object?>{};
  int status = 200;
  DioExceptionType? failure;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (failure != null) {
      throw DioException(requestOptions: options, type: failure!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
