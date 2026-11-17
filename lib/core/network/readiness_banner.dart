import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/application/session_controller.dart';
import 'backend_readiness.dart';

class ReadinessBanner extends ConsumerWidget {
  const ReadinessBanner({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ValueListenableBuilder(
    valueListenable: ref.watch(backendReadinessProvider),
    builder: (context, status, _) => Column(
      children: [
        if (status == Readiness.connecting || status == Readiness.failed)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (status == Readiness.connecting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status == Readiness.connecting
                            ? 'Connecting to the workshop. Startup can take up to 90 seconds.'
                            : 'The workshop is temporarily unavailable. Your session is preserved.',
                      ),
                    ),
                    if (status == Readiness.failed)
                      TextButton(
                        onPressed: () async {
                          try {
                            await ref.read(backendReadinessProvider).ensure();
                            if (context.mounted) {
                              ref.invalidate(sessionProvider);
                            }
                          } catch (_) {}
                        },
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    ),
  );
}
