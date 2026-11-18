import 'package:dio/dio.dart';

import 'package:assessment_project_fb_international_frontend/core/session/data/token_refresh_coordinator.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';

/// Check ownership again after asynchronous cookie/CSRF work, before dispatch.
class SessionGuardInterceptor extends Interceptor {
  SessionGuardInterceptor(this._coordinator);
  final TokenRefreshCoordinator _coordinator;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra.containsKey('authGeneration') &&
        (!_coordinator.enabled ||
            options.extra['authGeneration'] != _coordinator.generation)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const InvalidSessionException(),
        ),
      );
      return;
    }
    handler.next(options);
  }
}
