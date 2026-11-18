import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/catalog_state.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/catalog_cache.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, CatalogState>(
      CatalogController.new,
    );

/// Also expires disk state when Explore has never been mounted in this session.
Future<void> invalidatePublicCatalog(Ref ref) async {
  final expiring = ref.read(catalogCacheProvider)?.expire();
  ref.invalidate(catalogControllerProvider);
  await expiring;
}

class CatalogController extends AsyncNotifier<CatalogState> {
  int _generation = 0;
  Future<CatalogState>? _request;

  @override
  Future<CatalogState> build() async {
    final generation = _generation;
    ref.onDispose(() => _generation++);
    final forceRefresh = ref.isRefresh;
    _request = null;
    final service = ref.watch(serviceCatalogProvider);
    final cache = ref.watch(catalogCacheProvider);
    final cached = await cache?.read();
    if (generation != _generation) return const CatalogState();
    if (cached != null && !forceRefresh && cached.isFreshAt(DateTime.now())) {
      return cached;
    }
    final request = _request = _fetch(generation, service, cache, cached);
    if (cached != null) state = AsyncData(cached.copyWith(refreshing: true));
    return request;
  }

  Future<CatalogState> _fetch(
    int generation,
    ServiceCatalogService service,
    CatalogCache? cache,
    CatalogState? previous,
  ) async {
    final result = await ApiErrorHandler.run(service.getServices);
    final services = result.data;
    if (services == null) {
      return (previous ?? const CatalogState()).copyWith(
        errorCode: result.errorCode,
        refreshing: false,
      );
    }
    final updatedAt = DateTime.now().toUtc();
    if (generation == _generation && cache != null) {
      await cache.write(services, updatedAt);
    }
    return CatalogState(services: services, updatedAt: updatedAt);
  }

  Future<void> refreshIfStale() async {
    final current = state.asData?.value;
    if (current != null &&
        ref.read(catalogCacheProvider) != null &&
        !current.isFreshAt(DateTime.now())) {
      await refresh();
    }
  }

  Future<void> refresh() async {
    final generation = _generation;
    final current = state.asData?.value;
    if (current == null) {
      await future;
      if (generation != _generation) return;
      // A pull during disk hydration must still reach the network on a fresh hit.
      if (_request == null) return refresh();
      await _request;
      return;
    }
    if (current.refreshing) {
      await _request;
      return;
    }
    final request = _request = _fetch(
      generation,
      ref.read(serviceCatalogProvider),
      ref.read(catalogCacheProvider),
      current,
    );
    state = AsyncData(current.copyWith(refreshing: true, clearError: true));
    final latest = await request;
    if (generation == _generation) state = AsyncData(latest);
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

final featuredServicesProvider = Provider<List<ServiceModel>>(
  (ref) => List.unmodifiable(
    ref.watch(catalogServicesProvider).where((service) => service.isFeatured),
  ),
);
