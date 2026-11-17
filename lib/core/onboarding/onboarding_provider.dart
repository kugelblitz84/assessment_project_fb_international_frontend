import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingProvider = AsyncNotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
  retry: (retryCount, error) => null,
);

class OnboardingController extends AsyncNotifier<bool> {
  static const completionKey = 'autocare.onboarding.complete';

  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(completionKey) ?? false;

  Future<void> complete() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(completionKey, true)) {
      throw StateError('Unable to save onboarding completion.');
    }
    if (ref.mounted) state = const AsyncData(true);
  }
}
