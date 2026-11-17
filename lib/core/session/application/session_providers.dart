import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/auth_repository_impl.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_repository.dart';

export 'package:assessment_project_fb_international_frontend/core/session/application/token_storage_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(dioProvider),
    coordinator: ref.watch(tokenRefreshCoordinatorProvider),
    transport: ref.watch(authTransportProvider),
  ),
);
