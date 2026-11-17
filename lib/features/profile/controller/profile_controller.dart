import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../../../core/session/domain/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../model/profile_state.dart';
import '../model/update_profile_payload.dart';
import '../service/profile_service.dart';

final profileControllerProvider =
    NotifierProvider.autoDispose<ProfileController, ProfileState>(
      ProfileController.new,
    );

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    ref.watch(sessionIdentityProvider);
    return const ProfileState();
  }

  Future<bool> save(UpdateProfilePayload payload) async {
    final identity = ref.read(sessionIdentityProvider);
    final session = ref.read(sessionProvider).asData?.value;
    if (state.saving || session is! Authenticated) return false;
    if (payload.name.trim().isEmpty ||
        payload.name.trim().length > 160 ||
        payload.email.trim().length > 320 ||
        Validators.email(payload.email) != null) {
      state = const ProfileState(errorCode: 'VALIDATION_ERROR');
      return false;
    }
    state = const ProfileState(saving: true);
    final result = await ApiErrorHandler.run(
      () => ref.read(profileServiceProvider).update(session.user.id, payload),
    );
    if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) {
      return false;
    }
    if (result.success) {
      ref.read(sessionProvider.notifier).updateUser(result.data!);
    }
    state = ProfileState(errorCode: result.errorCode, saved: result.success);
    return result.success;
  }
}
