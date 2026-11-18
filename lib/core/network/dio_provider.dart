import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/config/api_config.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/backend_policy.dart';
import 'package:assessment_project_fb_international_frontend/core/network/cookie_transport.dart';
import 'package:assessment_project_fb_international_frontend/core/network/interceptors/auth_interceptor.dart';
import 'package:assessment_project_fb_international_frontend/core/network/interceptors/csrf_interceptor.dart';
import 'package:assessment_project_fb_international_frontend/core/network/interceptors/session_guard_interceptor.dart';
import 'package:assessment_project_fb_international_frontend/core/network/transport_timeouts.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/token_refresh_coordinator.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/token_storage_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/api_error_messages.dart';

final backendPolicyProvider = Provider(
  (ref) => BackendPolicy(Uri.parse(ref.watch(apiBaseUrlProvider))),
);
final cookieTransportProvider = Provider(
  (ref) => CookieTransport(ref.watch(backendPolicyProvider).base),
);
Dio _client(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiBaseUrlProvider),
      connectTimeout: TransportTimeouts.connect,
      receiveTimeout: TransportTimeouts.receive,
      sendTimeout: TransportTimeouts.send,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': Headers.jsonContentType},
      followRedirects: false,
    ),
  );
  ref
      .watch(cookieTransportProvider)
      .configure(dio, ref.watch(backendPolicyProvider).trusted);
  if (kIsWeb) {
    dio.interceptors.add(
      CsrfInterceptor(dio, ref.watch(backendPolicyProvider)),
    );
  }
  ref.onDispose(() => dio.close(force: true));
  return dio;
}

final authTransportProvider = Provider<Dio>(_client);
final tokenRefreshCoordinatorProvider = Provider((ref) {
  final transport = ref.watch(authTransportProvider);
  return TokenRefreshCoordinator(ref.watch(tokenStorageProvider), () async {
    try {
      final response = await transport.post<Object?>(ApiEndpoints.refresh);
      final body = response.data;
      if (body is! Map ||
          body['accessToken'] is! String ||
          (body['accessToken'] as String).trim().isEmpty) {
        throw const InvalidAuthResponseException();
      }
      return body['accessToken'] as String;
    } on DioException catch (error) {
      if (error.error is SessionException) throw error.error!;
      if (error.response?.statusCode == 401) {
        throw const InvalidSessionException();
      }
      throw AuthRequestException(
        ApiErrorMessages.messageFor(ApiErrorHandler.codeFor(error)),
        code: ApiErrorHandler.codeFor(error),
      );
    }
  }, ref.watch(cookieTransportProvider).clear);
});
final dioProvider = Provider<Dio>((ref) {
  final dio = _client(ref);
  dio.interceptors.insert(
    0,
    AuthInterceptor(
      tokenStorage: ref.watch(tokenStorageProvider),
      apiBaseUri: ref.watch(backendPolicyProvider).base,
      dio: dio,
      coordinator: ref.watch(tokenRefreshCoordinatorProvider),
    ),
  );
  final coordinator = ref.watch(tokenRefreshCoordinatorProvider);
  dio.interceptors.add(SessionGuardInterceptor(coordinator));
  return dio;
});
