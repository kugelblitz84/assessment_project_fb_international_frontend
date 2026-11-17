import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../model/catalog_state.dart';
import '../model/service_model.dart';
import '../service/service_catalog_service.dart';

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, CatalogState>(
      CatalogController.new,
    );

class CatalogController extends AsyncNotifier<CatalogState> {
  int _generation = 0;
  @override
  Future<CatalogState> build() async {
    _generation++;
    final service = ref.watch(serviceCatalogProvider);
    final result = await ApiErrorHandler.run(service.getServices);
    return CatalogState(
      services: result.data ?? const [],
      errorCode: result.errorCode,
    );
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null || current.refreshing) return;
    final generation = _generation;
    state = AsyncData(current.copyWith(refreshing: true, clearError: true));
    final result = await ApiErrorHandler.run(
      () => ref.read(serviceCatalogProvider).getServices(),
    );
    if (!ref.mounted || generation != _generation) return;
    state = AsyncData(
      current.copyWith(
        services: result.data,
        errorCode: result.errorCode,
        clearError: result.success,
        refreshing: false,
      ),
    );
  }
}

/// Reusable catalogue projections avoid watching loading/refresh flags in cards.
final catalogServicesProvider = Provider<List<ServiceModel>>(
  (ref) => ref.watch(
    catalogControllerProvider.select(
      (catalog) => catalog.asData?.value.services ?? const <ServiceModel>[],
    ),
  ),
);
final catalogByIdProvider = Provider<Map<String, ServiceModel>>(
  (ref) => Map.unmodifiable({
    for (final service in ref.watch(catalogServicesProvider))
      service.id: service,
  }),
);
