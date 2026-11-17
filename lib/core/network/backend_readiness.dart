import 'api_endpoints.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/demo_mode.dart';
import 'dio_provider.dart';

enum Readiness { idle, connecting, ready, failed }

final backendReadinessProvider = Provider((ref) {
  final base = ref.watch(apiBaseUrlProvider);
  final demo = ref.watch(demoModeProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 90),
      followRedirects: false,
    ),
  );
  final readiness = BackendReadiness(() async {
    if (demo) return;
    final cancel = CancelToken();
    final response = await dio
        .get<Object?>(ApiEndpoints.health, cancelToken: cancel)
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            cancel.cancel('Readiness deadline');
            throw TimeoutException('Readiness deadline');
          },
        );
    if (response.data is! Map || (response.data as Map)['status'] != 'ok') {
      throw const FormatException('Backend is not ready.');
    }
  });
  ref.onDispose(() {
    dio.close(force: true);
    readiness.dispose();
  });
  return readiness;
});

/// One bounded readiness request shared by both authenticated transports.
class BackendReadiness extends ValueNotifier<Readiness> {
  BackendReadiness(this.check) : super(Readiness.idle);
  final Future<void> Function() check;
  Future<void>? _pending;
  DateTime? _checkedAt;
  bool _disposed = false;
  Future<void> ensure() {
    if (_pending != null) return _pending!;
    if (_checkedAt != null &&
        DateTime.now().difference(_checkedAt!) < const Duration(minutes: 5)) {
      return Future.value();
    }
    return _pending = _run();
  }

  Future<void> _run() async {
    value = Readiness.connecting;
    try {
      await check().timeout(const Duration(seconds: 90));
      _checkedAt = DateTime.now();
      if (!_disposed) value = Readiness.ready;
    } catch (_) {
      _checkedAt = null;
      if (!_disposed) value = Readiness.failed;
      rethrow;
    } finally {
      _pending = null;
    }
  }

  void unavailable() {
    _checkedAt = null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ReadinessInterceptor extends Interceptor {
  ReadinessInterceptor(this.readiness);
  final BackendReadiness readiness;
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      await readiness.ensure();
      final longOperation =
          options.path.contains('/payments') ||
          options.path.endsWith('/pay') ||
          options.path == '/assistant/chat';
      if (longOperation || options.path == '/admin/media/images') {
        options.receiveTimeout = const Duration(seconds: 75);
        options.sendTimeout = const Duration(seconds: 60);
      }
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const BackendUnavailable(),
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout ||
        err.response?.statusCode == 503) {
      readiness.unavailable();
    }
    // Retrying reads is left to explicit UI actions; mutations are never replayed.
    handler.next(err);
  }
}

class BackendUnavailable implements Exception {
  const BackendUnavailable();
}
