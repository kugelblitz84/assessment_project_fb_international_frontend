import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';

void main() {
  group('ApiErrorHandler', () {
    test('preserves typed service data and calls the operation once', () async {
      final services = ['service-1'];
      var calls = 0;

      final result = await ApiErrorHandler.run(() async {
        calls++;
        return services;
      });

      expect(result.success, isTrue);
      expect(result.data, same(services));
      expect(result.errorCode, isNull);
      expect(calls, 1);
    });

    test('void and nullable successes are distinct from failures', () async {
      final noContent = await ApiErrorHandler.run<void>(() async {});
      final nullable = await ApiErrorHandler.run<String?>(() async => null);

      expect(noContent.success, isTrue);
      expect(noContent.errorCode, isNull);
      expect(nullable.success, isTrue);
      expect(nullable.data, isNull);
      expect(nullable.errorCode, isNull);
    });

    for (final (type, code) in [
      (DioExceptionType.connectionTimeout, 'CONNECTION_TIMEOUT'),
      (DioExceptionType.sendTimeout, 'SEND_TIMEOUT'),
      (DioExceptionType.receiveTimeout, 'RECEIVE_TIMEOUT'),
      (DioExceptionType.connectionError, 'NETWORK_ERROR'),
      (DioExceptionType.cancel, 'CANCELLED'),
      (DioExceptionType.badCertificate, 'UNEXPECTED_ERROR'),
      (DioExceptionType.unknown, 'UNEXPECTED_ERROR'),
    ]) {
      test('maps $type to a safe failure', () async {
        final result = await ApiErrorHandler.run<Object?>(
          () async => throw DioException(
            requestOptions: RequestOptions(path: '/resource'),
            type: type,
            message: 'private transport details',
          ),
        );

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.errorCode, code);
      });
    }

    for (final (status, code) in [
      (400, 'VALIDATION_ERROR'),
      (422, 'VALIDATION_ERROR'),
      (401, 'UNAUTHORIZED'),
      (403, 'FORBIDDEN'),
      (404, 'NOT_FOUND'),
      (409, 'CONFLICT'),
      (429, 'RATE_LIMITED'),
      (500, 'SERVER_ERROR'),
      (503, 'BACKEND_UNAVAILABLE'),
      (418, 'UNEXPECTED_ERROR'),
    ]) {
      test('maps HTTP $status without exposing the response body', () async {
        final result = await ApiErrorHandler.run<Object?>(
          () async => throw _httpFailure(status, {
            'code': 'private backend code',
            'message': 'private backend details',
          }),
        );

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.errorCode, code);
        final message = AppErrorMessages.messageFor(result.errorCode);
        expect(message, isNotEmpty);
        expect(message, isNot(contains('private')));
      });
    }

    test('does not interpret unverified slot conflict codes', () async {
      for (final body in [
        null,
        'private backend details',
        <Object?>[],
        {'code': 'SLOT_UNAVAILABLE'},
        {'code': 42},
      ]) {
        final result = await ApiErrorHandler.run<Object?>(
          () async => throw _httpFailure(409, body),
        );

        expect(result.success, isFalse);
        expect(result.errorCode, 'CONFLICT');
      }
    });

    for (final (failure, code) in <(SessionException, String)>[
      (const InvalidSessionException(), 'SESSION_EXPIRED'),
      (const InvalidCredentialsException(), 'INVALID_CREDENTIALS'),
      (
        const InvalidAuthResponseException('private response details'),
        'INVALID_RESPONSE',
      ),
      (
        const AuthRequestException('private request details'),
        'UNEXPECTED_ERROR',
      ),
    ]) {
      test('maps direct and Dio-wrapped ${failure.runtimeType}', () async {
        for (final error in <Object>[
          failure,
          DioException(
            requestOptions: RequestOptions(path: '/resource'),
            error: failure,
          ),
        ]) {
          final result = await ApiErrorHandler.run<Object?>(
            () async => throw error,
          );

          expect(result.success, isFalse);
          expect(result.data, isNull);
          expect(result.errorCode, code);
        }
      });
    }

    test(
      'distinguishes malformed responses from programming type errors',
      () async {
        final malformed = await ApiErrorHandler.run<String>(
          () => throw const FormatException('private payload'),
        );
        final wrongType = await ApiErrorHandler.run<String>(() async {
          final json = <String, Object?>{'name': 42};
          return json['name'] as String;
        });

        for (final result in [malformed, wrongType]) {
          expect(result.success, isFalse);
          expect(result.data, isNull);
        }
        expect(malformed.errorCode, 'INVALID_RESPONSE');
        expect(wrongType.errorCode, 'UNEXPECTED_ERROR');
      },
    );

    test('maps malformed HTTP JSON wrapped by Dio', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = _MalformedJsonAdapter();
      addTearDown(dio.close);

      final result = await ApiErrorHandler.run(
        () => dio.get<Object?>('/resource'),
      );

      expect(result.success, isFalse);
      expect(result.errorCode, 'INVALID_RESPONSE');
    });

    test('does not retry mutations or expose unexpected exceptions', () async {
      var calls = 0;
      final result = await ApiErrorHandler.run<Object?>(() async {
        calls++;
        throw StateError('private mutation details');
      });

      expect(result.success, isFalse);
      expect(result.data, isNull);
      expect(result.errorCode, 'UNEXPECTED_ERROR');
      expect(calls, 1);
    });

    test('message lookup falls back safely for unknown and null codes', () {
      for (final code in [null, '', 'private backend details']) {
        expect(
          AppErrorMessages.messageFor(code),
          'Something went wrong. Please try again.',
        );
      }
    });
  });
}

DioException _httpFailure(int status, Object? body) {
  final options = RequestOptions(path: '/resource');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

class _MalformedJsonAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{invalid json',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
