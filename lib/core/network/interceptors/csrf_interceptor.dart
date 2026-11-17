import 'package:dio/dio.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/backend_policy.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';

/// Browser refresh/logout require a session-bound token from the trusted API.
class CsrfInterceptor extends Interceptor {
  CsrfInterceptor(this._dio, this._policy);
  final Dio _dio;
  final BackendPolicy _policy;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_policy.trusted(options.uri) ||
        !{ApiEndpoints.refresh, ApiEndpoints.logout}.contains(options.path)) {
      handler.next(options);
      return;
    }
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.csrf);
      final json = response.data;
      if (json is! Map ||
          json['csrfToken'] is! String ||
          (json['csrfToken'] as String).isEmpty) {
        throw const InvalidAuthResponseException();
      }
      options.headers['X-CSRF-Token'] = json['csrfToken'];
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error is DioException && error.response?.statusCode == 401
              ? const InvalidSessionException()
              : error,
        ),
      );
    }
  }
}
