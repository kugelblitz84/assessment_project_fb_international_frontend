import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/onboarding_provider.dart';

class BootstrapErrorPage extends ConsumerWidget {
  const BootstrapErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('AutoCare')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load your app preferences. Please try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(onboardingProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}
