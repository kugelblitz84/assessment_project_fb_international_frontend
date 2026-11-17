import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/session/domain/auth_state.dart';
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
    ref.watch(sessionProvider);
    return const ProfileState();
  }

  Future<bool> save(UpdateProfilePayload payload) async {
    final session = ref.read(sessionProvider).asData?.value;
    if (state.saving || session is! Authenticated) return false;
    state = const ProfileState(saving: true);
    final result = await ApiErrorHandler.run(
      () => ref.read(profileServiceProvider).update(session.user.id, payload),
    );
    if (!ref.mounted ||
        !identical(session, ref.read(sessionProvider).asData?.value)) {
      return false;
    }
    state = ProfileState(errorCode: result.errorCode);
    if (result.success) {
      ref.read(sessionProvider.notifier).updateUser(result.data!);
    }
    return result.success;
  }
}
