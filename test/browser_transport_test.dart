import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assessment_project_fb_international_frontend/core/network/backend_policy.dart';
import 'package:assessment_project_fb_international_frontend/core/network/cookie_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'browser sign-out intent survives transport recreation and explicit login clears it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final uri = Uri.parse('https://api.example.test/api/v1');
      final first = CookieTransport(uri);
      expect(await first.restorationBlocked(), isFalse);
      await first.clear();
      final reloaded = CookieTransport(uri);
      expect(await reloaded.restorationBlocked(), isTrue);
      await reloaded.allowRestoration();
      expect(await CookieTransport(uri).restorationBlocked(), isFalse);
      expect(
        await CookieTransport(
          Uri.parse('https://other.example.test/api/v1'),
        ).restorationBlocked(),
        isFalse,
      );
    },
    skip: !kIsWeb,
  );

  test(
    'credentialed browser transport rejects an untrusted destination before dispatch',
    () async {
      final base = Uri.parse('https://api.example.test/api/v1');
      final dio = Dio(BaseOptions(baseUrl: base.toString()));
      addTearDown(dio.close);
      CookieTransport(base).configure(dio, BackendPolicy(base).trusted);
      await expectLater(
        dio.get<Object?>('https://external.example.test/resource'),
        throwsA(isA<DioException>()),
      );
    },
    skip: !kIsWeb,
  );
}
