import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/api_error_messages.dart';

final adminAccessProvider = Provider.autoDispose((ref) {
  ref.watch(sessionIdentityProvider);
  final auth = ref.watch(sessionProvider).asData?.value;
  return auth is Authenticated && auth.user.isAdmin;
});
typedef AdminOwner = ({SessionIdentity identity, bool authorized});
final adminOwnerProvider = Provider.autoDispose<AdminOwner>(
  (ref) => (
    identity: ref.watch(sessionIdentityProvider),
    authorized: ref.watch(adminAccessProvider),
  ),
);
typedef AdminResourceKey = ({AdminOwner owner, String id});

class AdminFailure extends ApiFailure {
  const AdminFailure(super.code);
  @override
  String toString() => ApiErrorMessages.messageFor(code);
}

Future<T> loadAdmin<T>(
  Ref ref,
  AdminOwner owner,
  Future<T> Function() action,
) async {
  if (owner != ref.watch(adminOwnerProvider) || !owner.authorized) {
    throw const AdminFailure('FORBIDDEN');
  }
  final operation = ref.keepAlive();
  try {
    final result = await ApiErrorHandler.run(action);
    if (!ref.mounted || owner != ref.read(adminOwnerProvider)) {
      throw const AdminFailure('SESSION_EXPIRED');
    }
    if (!result.success) throw AdminFailure(result.errorCode!);
    return result.data as T;
  } finally {
    operation.close();
  }
}
