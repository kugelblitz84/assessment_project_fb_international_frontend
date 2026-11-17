import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/session/application/session_identity_provider.dart';
import '../../shared/controller/admin_providers.dart';
import '../../shared/service/admin_repository.dart';

final adminImagePickerProvider = Provider<Future<XFile?> Function()>(
  (ref) =>
      () => ImagePicker().pickImage(source: ImageSource.gallery),
);

class AdminImageState {
  const AdminImageState({
    this.url,
    this.bytes,
    this.name,
    this.busy = false,
    this.errorCode,
  });
  final String? url, name, errorCode;
  final Uint8List? bytes;
  final bool busy;
}

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
      if (await file.length() > AdminRepository.maxImageBytes) {
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
      AdminRepository.imageRequest(bytes, file.name);
      state = AdminImageState(url: previousUrl, bytes: bytes, name: file.name);
      await upload();
    } catch (_) {
      if (ref.mounted && identity == ref.read(sessionIdentityProvider)) {
        state = AdminImageState(
          url: previousUrl,
          errorCode: 'VALIDATION_ERROR',
        );
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
          .read(adminRepositoryProvider)
          .upload(current.bytes!, current.name!),
    );
    if (!ref.mounted || identity != ref.read(sessionIdentityProvider)) return;
    // Multipart bodies are never automatically replayed. Renew once, then let
    // the administrator explicitly retry with a newly constructed FormData.
    if (result.errorCode == 'UNAUTHORIZED') {
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
