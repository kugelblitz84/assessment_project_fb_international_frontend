import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_auth.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_overrides.dart';

/// Both entry points share one composition root. ProviderScope owns dependencies;
/// SessionController restores credentials after the loading frame mounts.
void bootstrap({bool offlineDemo = false}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        if (offlineDemo || const bool.fromEnvironment('DEMO_DATA'))
          ...demoServiceOverrides(),
        if (offlineDemo) ...[
          demoModeProvider.overrideWithValue(true),
          tokenStorageProvider.overrideWithValue(DemoTokenStorage()),
          cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
          authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
        ],
      ],
      child: const App(),
    ),
  );
}
