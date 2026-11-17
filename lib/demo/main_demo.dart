import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../core/config/demo_mode.dart';
import '../core/network/dio_provider.dart';
import '../core/session/application/session_providers.dart';
import 'demo_auth.dart';

/// Explicit, in-memory UI demo. The normal main.dart keeps real authentication.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        demoModeProvider.overrideWithValue(true),
        tokenStorageProvider.overrideWithValue(DemoTokenStorage()),
        cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
        authRepositoryProvider.overrideWithValue(DemoAuthRepository()),
      ],
      child: const App(),
    ),
  );
}
