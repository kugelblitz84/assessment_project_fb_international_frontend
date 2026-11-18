import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/validators.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/profile_state.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/model/update_profile_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/profile/service/profile_service.dart';

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
