import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';

class SecureCookieStorage implements Storage {
  SecureCookieStorage(this.namespace);
  final String namespace;
  final _storage = const FlutterSecureStorage();
  String key(String name) => 'autocare.cookies.$namespace.$name';
  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}
  @override
  Future<String?> read(String name) =>
      _guard(() => _storage.read(key: key(name)));
  @override
  Future<void> write(String name, String value) =>
      _guard(() => _storage.write(key: key(name), value: value));
  @override
  Future<void> delete(String name) =>
      _guard(() => _storage.delete(key: key(name)));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      throw const SecureStorageException();
    }
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final name in keys) {
      await delete(name);
    }
  }
}

class CookieTransport {
  CookieTransport(this.base)
    : jar = PersistCookieJar(
        storage: SecureCookieStorage(Uri.encodeComponent(base.toString())),
        persistSession: true,
      );
  final PersistCookieJar jar;
  final Uri base;
  Future<bool> restorationBlocked() async => false;
  Future<void> blockRestoration() async {}
  Future<void> allowRestoration() async {}
  Future<bool> canRestoreSession() async => (await jar.loadForRequest(
    Uri.parse(
      '${base.toString().replaceFirst(RegExp(r'/+$'), '')}/auth/refresh',
    ),
  )).isNotEmpty;
  void configure(Dio dio, bool Function(Uri) trusted) {
    dio.interceptors.add(_TrustedCookies(jar, trusted));
  }

  Future<void> clear() => jar.deleteAll();
}

class _TrustedCookies extends CookieManager {
  _TrustedCookies(super.jar, this.trusted);
  final bool Function(Uri) trusted;
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.removeWhere((key, _) => key.toLowerCase() == 'cookie');
    if (!trusted(options.uri)) {
      handler.next(options);
      return;
    }
    await super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (!trusted(response.requestOptions.uri)) {
      handler.next(response);
      return;
    }
    await super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (!trusted(error.requestOptions.uri)) {
      handler.next(error);
      return;
    }
    await super.onError(error, handler);
  }
}
