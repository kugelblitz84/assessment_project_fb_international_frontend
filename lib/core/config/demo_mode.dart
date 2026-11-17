import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demo data is an explicit development/testing option.
/// Authentication is real unless running the separate lib/demo/main_demo.dart.
final demoModeProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('DEMO_DATA', defaultValue: false),
);
