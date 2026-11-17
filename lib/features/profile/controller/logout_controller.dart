import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/application/session_controller.dart';
import '../model/logout_state.dart';

final logoutControllerProvider =
    NotifierProvider.autoDispose<LogoutController, LogoutState>(
      LogoutController.new,
    );

class LogoutController extends Notifier<LogoutState> {
  @override
  LogoutState build() => const LogoutState();
  Future<void> logout() async {
    if (state.loading) return;
    state = const LogoutState(loading: true);
    try {
      await ref.read(sessionProvider.notifier).logout();
      if (ref.mounted) state = const LogoutState();
    } catch (_) {
      if (ref.mounted) {
        state = const LogoutState(
          error: 'Unable to clear your session. Please try again.',
        );
      }
    }
  }
}
