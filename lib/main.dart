import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/app.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_overrides.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: const bool.fromEnvironment('DEMO_DATA')
          ? demoServiceOverrides()
          : [],
      child: const App(),
    ),
  );
}
