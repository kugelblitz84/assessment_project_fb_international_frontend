import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sample business data is enabled until backend integration is supplied.
/// Authentication is real unless running the separate lib/demo/main_demo.dart.
final demoModeProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('DEMO_DATA', defaultValue: true),
);
