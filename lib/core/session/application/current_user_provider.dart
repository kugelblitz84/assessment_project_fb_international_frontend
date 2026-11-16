import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_controller.dart';

import '../domain/auth_state.dart';
import '../domain/user_entity.dart';

final currentUserProvider = Provider<UserEntity?>((ref) {
  final session = ref.watch(sessionProvider);

  if (session.isLoading || session.hasError) return null;

  final authState = session.asData?.value;

  return switch (authState) {
    Authenticated(:final user) => user,
    Unauthenticated() => null,
    _ => null,
  };
});
