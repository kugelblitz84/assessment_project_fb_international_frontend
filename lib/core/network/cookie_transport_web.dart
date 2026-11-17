import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CookieTransport {
  CookieTransport(Uri base)
    : _signOutKey = 'autocare.signedOut.${base.origin}${base.path}';
  final String _signOutKey;
  Future<bool> restorationBlocked() async =>
      (await SharedPreferences.getInstance()).getBool(_signOutKey) ?? false;
  Future<void> blockRestoration() => clear();
  Future<void> allowRestoration() async {
    if (!await (await SharedPreferences.getInstance()).remove(_signOutKey)) {
      throw StateError('Unable to enable browser session restoration.');
    }
  }

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

  Future<void> clear() async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      _signOutKey,
      true,
    )) {
      throw StateError('Unable to remember browser sign-out.');
    }
  }
}
