import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/dio_provider.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';

export 'token_storage_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(dioProvider),
    coordinator: ref.watch(tokenRefreshCoordinatorProvider),
    transport: ref.watch(authTransportProvider),
  ),
);
