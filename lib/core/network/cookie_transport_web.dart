import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

class CookieTransport {
  CookieTransport(Uri base);
  // HttpOnly refresh cookies are intentionally invisible to application code.
  Future<bool> canRestoreSession() async => true;
  void configure(Dio dio, bool Function(Uri) trusted) {
    dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!trusted(options.uri)) {
            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Untrusted destination.',
              ),
            );
          } else {
            handler.next(options);
          }
        },
      ),
    );
  }

  Future<void> clear() async {}
}
