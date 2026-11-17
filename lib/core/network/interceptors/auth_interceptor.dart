import 'package:dio/dio.dart';

import 'package:assessment_project_fb_international_frontend/core/network/backend_policy.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/token_refresh_coordinator.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Uri apiBaseUri,
    required Dio dio,
    required TokenRefreshCoordinator coordinator,
  }) : _tokenStorage = tokenStorage,
       _apiBaseUri = apiBaseUri,
       _dio = dio,
       _coordinator = coordinator;

  final TokenStorage _tokenStorage;
  final Uri _apiBaseUri;
  final Dio _dio;
  final TokenRefreshCoordinator _coordinator;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final policy = BackendPolicy(_apiBaseUri);
    if (!policy.trusted(options.uri) ||
        policy.isAuthEndpoint(options.uri) ||
        options.extra[requestAccessKey] == RequestAccess.public) {
      options.headers.removeWhere(
        (key, value) => key.toLowerCase() == 'authorization',
      );
      handler.next(options);
      return;
    }

    final optional = options.extra[requestAccessKey] == RequestAccess.optional;
    if (optional && _coordinator.enabled == false) {
      options.headers.removeWhere(
        (key, _) => key.toLowerCase() == 'authorization',
      );
      handler.next(options);
      return;
    }
    options.followRedirects = false;
    options.extra.putIfAbsent('authGeneration', () => _coordinator.generation);
    if ((!_coordinator.enabled ||
        options.extra['authGeneration'] != _coordinator.generation)) {
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
      if ((!_coordinator.enabled ||
          options.extra['authGeneration'] != _coordinator.generation)) {
        throw const InvalidSessionException();
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else if (!optional) {
        throw const InvalidSessionException();
      }
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error is SessionException
              ? error
              : const SecureStorageException(),
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
    if (options.extra['authGeneration'] != _coordinator.generation) {
      handler.next(err);
      return;
    }
    if (err.response?.statusCode != 401 ||
        (code is Map &&
            code['code'] != null &&
            code['code'] != 'ACCESS_TOKEN_EXPIRED') ||
        !policy.trusted(options.uri) ||
        policy.isAuthEndpoint(options.uri) ||
        options.extra[requestAccessKey] == RequestAccess.public ||
        options.extra['authRetried'] == true ||
        authorization is! String ||
        !authorization.startsWith('Bearer ') ||
        options.data is Stream ||
        options.data is FormData) {
      handler.next(err);
      return;
    }
    try {
      final token = await _coordinator.refresh(
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
        await _dio.fetch<dynamic>(
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
