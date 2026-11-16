import 'package:dio/dio.dart';

import '../session/domain/token_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenStorage tokenStorage, required Uri apiBaseUri})
    : _tokenStorage = tokenStorage,
      _apiBaseUri = apiBaseUri;

  final TokenStorage _tokenStorage;
  final Uri _apiBaseUri;

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
        requestPath == '$basePath${ApiEndpoints.register}';

    if (!isBackend || isAuthRequest) {
      options.headers.removeWhere(
        (key, value) => key.toLowerCase() == 'authorization',
      );
      handler.next(options);
      return;
    }

    options.followRedirects = false;
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
}
