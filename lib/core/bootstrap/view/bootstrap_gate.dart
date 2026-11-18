import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';

/// Keeps routed pages unmounted until session restoration settles. Transient
/// failures allow browsing; SessionController retains credentials for retry.
class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key, required this.loading, required this.child});

  final Widget loading;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sessionProvider.select((session) => session.isLoading))
      ? loading
      : child;
}
