import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_auth.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_overrides.dart';

/// Explicit, in-memory UI demo. The normal main.dart keeps real authentication.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        ...demoServiceOverrides(),
        demoModeProvider.overrideWithValue(true),
        tokenStorageProvider.overrideWithValue(DemoTokenStorage()),
        cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
        authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
      ],
      child: const App(),
    ),
  );
}
