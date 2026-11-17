import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/application/token_storage_provider.dart';
import '../session/application/token_refresh_coordinator.dart';
import '../session/domain/session_exception.dart';
import 'auth_interceptor.dart';
import 'api_endpoints.dart';
import 'backend_policy.dart';
import 'cookie_transport.dart';
import 'backend_readiness.dart';

final apiBaseUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://fb-international-assessment-project.onrender.com/api/v1',
  ),
);
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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': Headers.jsonContentType},
      followRedirects: false,
    ),
  );
  dio.interceptors.add(
    ReadinessInterceptor(ref.watch(backendReadinessProvider)),
  );
  ref
      .watch(cookieTransportProvider)
      .configure(dio, ref.watch(backendPolicyProvider).trusted);
  if (kIsWeb) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path != ApiEndpoints.refresh &&
              options.path != ApiEndpoints.logout) {
            handler.next(options);
            return;
          }
          try {
            final csrf = await dio.get<Object?>(ApiEndpoints.csrf);
            final data = csrf.data;
            if (data is! Map || data['csrfToken'] is! String) {
              throw const InvalidAuthResponseException();
            }
            options.headers['X-CSRF-Token'] = data['csrfToken'];
            handler.next(options);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: options,
                error:
                    error is DioException && error.response?.statusCode == 401
                    ? const InvalidSessionException()
                    : const AuthRequestException(
                        'Unable to verify browser session.',
                      ),
              ),
            );
          }
        },
      ),
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
      if (error.response?.statusCode == 401) {
        throw const InvalidSessionException();
      }
      throw const AuthRequestException(
        'Unable to renew the session. Please try again.',
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
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.extra.containsKey('authGeneration') &&
            (!coordinator.enabled ||
                options.extra['authGeneration'] != coordinator.generation)) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: const InvalidSessionException(),
            ),
          );
        } else {
          handler.next(options);
        }
      },
    ),
  );
  return dio;
});
