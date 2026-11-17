import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/model/admin_image_state.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/model/selected_image.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/service/admin_image_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';

final adminImagePickerProvider = Provider<Future<XFile?> Function()>(
  (ref) =>
      () => ImagePicker().pickImage(source: ImageSource.gallery),
);

typedef AdminImageKey = ({Object owner, String? initialUrl});

final adminImageProvider = NotifierProvider.autoDispose
    .family<AdminImageController, AdminImageState, AdminImageKey>(
      AdminImageController.new,
    );

class AdminImageController extends Notifier<AdminImageState> {
  AdminImageController(this.fieldKey);
  final AdminImageKey fieldKey;
  @override
  AdminImageState build() {
    ref.watch(sessionIdentityProvider);
    ref.watch(adminAccessProvider);
    return AdminImageState(url: fieldKey.initialUrl);
  }

  Future<void> select() async {
    if (state.busy || !ref.read(adminAccessProvider)) return;
    final identity = ref.read(sessionIdentityProvider);
    final previousUrl = state.url;
    state = AdminImageState(url: previousUrl, busy: true);
    try {
      final file = await ref.read(adminImagePickerProvider)();
      if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) return;
      if (file == null) {
        state = AdminImageState(url: previousUrl);
        return;
      }
      final size = await file.length();
      if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) return;
      if (size > SelectedImage.maxBytes) {
        if (ref.mounted) {
          state = AdminImageState(
            url: previousUrl,
            errorCode: 'IMAGE_TOO_LARGE',
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) return;
      // Validate before making a request; byte signatures are checked by the backend.
      SelectedImage(bytes, file.name);
      state = AdminImageState(url: previousUrl, bytes: bytes, name: file.name);
      await upload();
    } catch (error, stack) {
      final failure = await ApiErrorHandler.run<void>(() async {
        Error.throwWithStackTrace(error, stack);
      });
      if (ref.mounted && identity == ref.read(sessionIdentityProvider)) {
        state = AdminImageState(url: previousUrl, errorCode: failure.errorCode);
      }
    }
  }

  Future<void> upload() async {
    final current = state;
    if (current.busy ||
        current.bytes == null ||
        !ref.read(adminAccessProvider)) {
      return;
    }
    final identity = ref.read(sessionIdentityProvider);
    state = AdminImageState(
      url: current.url,
      bytes: current.bytes,
      name: current.name,
      busy: true,
    );
    final result = await ApiErrorHandler.run(
      () => ref
          .read(adminImageServiceProvider)
          .upload(SelectedImage(current.bytes!, current.name!)),
    );
    if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) return;
    // Multipart bodies are never automatically replayed. Renew once, then let
    // the administrator explicitly retry with a newly constructed FormData.
    if (result.errorCode == 'UNAUTHORIZED' ||
        result.errorCode == 'SESSION_EXPIRED') {
      await ApiErrorHandler.run(
        () => ref.read(tokenRefreshCoordinatorProvider).refresh(),
      );
      if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) return;
    }
    state = AdminImageState(
      url: result.data ?? current.url,
      bytes: result.success ? null : current.bytes,
      name: current.name,
      errorCode: result.errorCode,
    );
  }
}
