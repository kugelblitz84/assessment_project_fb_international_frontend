import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_state.dart';
import 'session_controller.dart';

/// Ownership changes reset private state. Editing the same user's profile does not.
/// Generation also distinguishes a later login to the same account.
typedef SessionIdentity = ({String? userId, int generation});

final sessionIdentityProvider = Provider<SessionIdentity>((ref) {
  return ref.watch(
    sessionProvider.select((session) {
      final auth = session.asData?.value;
      return auth is Authenticated
          ? (userId: auth.user.id, generation: auth.generation)
          : (userId: null, generation: -1);
    }),
  );
});
