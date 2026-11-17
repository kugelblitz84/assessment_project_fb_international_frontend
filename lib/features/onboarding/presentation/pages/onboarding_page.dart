import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/onboarding/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  bool _saving = false;
  String? _error;

  Future<void> _complete() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(onboardingProvider.notifier).complete();
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome to AutoCare')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Explore car care services and book when you are ready.'),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
          FilledButton(
            onPressed: _saving ? null : _complete,
            child: const Text('Get Started'),
          ),
          TextButton(
            onPressed: _saving ? null : _complete,
            child: const Text('Skip'),
          ),
        ],
      ),
    ),
  );
}
