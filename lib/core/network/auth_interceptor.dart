import 'package:dio/dio.dart';

import '../session/domain/token_storage.dart';
import 'api_endpoints.dart';
import '../session/application/token_refresh_coordinator.dart';
import '../session/domain/session_exception.dart';
import 'backend_policy.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Uri apiBaseUri,
    this.dio,
    this.coordinator,
  }) : _tokenStorage = tokenStorage,
       _apiBaseUri = apiBaseUri;

  final TokenStorage _tokenStorage;
  final Uri _apiBaseUri;
  final Dio? dio;
  final TokenRefreshCoordinator? coordinator;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = options.uri;
    final basePath = _apiBaseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final isBackend =
        uri.origin == _apiBaseUri.origin &&
        (basePath.isEmpty || uri.path.startsWith('$basePath/'));
    final requestPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    final isAuthRequest =
        requestPath == '$basePath${ApiEndpoints.login}' ||
        requestPath == '$basePath${ApiEndpoints.register}' ||
        requestPath == '$basePath${ApiEndpoints.refresh}' ||
        requestPath == '$basePath${ApiEndpoints.logout}';

    if (!isBackend || isAuthRequest) {
      options.headers.removeWhere(
        (key, value) => key.toLowerCase() == 'authorization',
      );
      handler.next(options);
      return;
    }

    options.followRedirects = false;
    options.extra.putIfAbsent('authGeneration', () => coordinator?.generation);
    if (coordinator != null &&
        (!coordinator!.enabled ||
            options.extra['authGeneration'] != coordinator!.generation)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const InvalidSessionException(),
        ),
      );
      return;
    }
    // /auth/me supplies its startup token explicitly; do not read it twice.
    final hasAuthorization = options.headers.keys.any(
      (key) => key.toLowerCase() == 'authorization',
    );
    if (hasAuthorization) {
      handler.next(options);
      return;
    }
    try {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: 'Unable to read the saved session.',
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final policy = BackendPolicy(_apiBaseUri);
    final authorization = options.headers.entries
        .where((e) => e.key.toLowerCase() == 'authorization')
        .firstOrNull
        ?.value;
    final code = err.response?.data;
    if (coordinator != null &&
        options.extra['authGeneration'] != coordinator!.generation) {
      handler.next(err);
      return;
    }
    if (err.response?.statusCode != 401 ||
        (code is Map &&
            code['code'] != null &&
            code['code'] != 'ACCESS_TOKEN_EXPIRED') ||
        !policy.trusted(options.uri) ||
        policy.public(options.uri) ||
        options.extra['authRetried'] == true ||
        authorization is! String ||
        !authorization.startsWith('Bearer ') ||
        options.data is Stream ||
        options.data is FormData ||
        coordinator == null ||
        dio == null) {
      handler.next(err);
      return;
    }
    try {
      final token = await coordinator!.refresh(
        failedToken: authorization.substring(7),
      );
      final headers = Map<String, dynamic>.from(options.headers)
        ..removeWhere(
          (key, _) =>
              key.toLowerCase() == 'authorization' ||
              key.toLowerCase() == 'cookie',
        );
      headers['Authorization'] = 'Bearer $token';
      handler.resolve(
        await dio!.fetch<dynamic>(
          options.copyWith(
            headers: headers,
            extra: {...options.extra, 'authRetried': true},
          ),
        ),
      );
    } catch (failure) {
      if (failure is DioException) {
        handler.reject(failure);
        return;
      }
      handler.reject(
        DioException(
          requestOptions: options,
          error: failure is SessionException
              ? failure
              : const AuthRequestException('Unable to renew the session.'),
          message: 'Session renewal failed.',
        ),
      );
    }
  }
}
