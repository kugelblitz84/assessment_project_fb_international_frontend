import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/session/application/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_state.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';

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
