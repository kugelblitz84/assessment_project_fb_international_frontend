import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_workshop.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/catalog_state.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/catalog_cache.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';

class _Cache extends CatalogCache {
  _Cache() : super('test');
  CatalogState? saved;

  @override
  Future<CatalogState?> read() async => saved;
  @override
  Future<void> write(List<ServiceModel> services, DateTime updatedAt) async {
    saved = CatalogState(services: services, updatedAt: updatedAt);
  }

  @override
  Future<void> expire() async {
    if (saved != null) {
      saved = CatalogState(
        services: saved!.services,
        updatedAt: DateTime.utc(2000),
      );
    }
  }
}

class _Catalog extends ServiceCatalogService {
  _Catalog() : super(Dio());
  int requests = 0;
  Completer<List<ServiceModel>>? pending;

  @override
  Future<List<ServiceModel>> getServices() async {
    requests++;
    return pending?.future ?? DemoWorkshop.services;
  }
}

ProviderContainer _launch(_Cache cache, _Catalog catalog) =>
    ProviderContainer.test(
      overrides: [
        catalogCacheProvider.overrideWithValue(cache),
        serviceCatalogProvider.overrideWithValue(catalog),
      ],
    );

void main() {
  test(
    'fresh launches reuse the full catalog and an authoritative empty list',
    () async {
      final cache = _Cache();
      final catalog = _Catalog();
      final first = _launch(cache, catalog);
      expect(
        (await first.read(catalogControllerProvider.future)).services,
        isNotEmpty,
      );
      expect(catalog.requests, 1);

      final next = _launch(cache, catalog);
      final restored = await next.read(catalogControllerProvider.future);
      expect(restored.services, DemoWorkshop.services);
      await next.read(catalogControllerProvider.notifier).refreshIfStale();
      expect(catalog.requests, 1);

      catalog.pending = Completer()..complete([]);
      await next.read(catalogControllerProvider.notifier).refresh();
      expect(catalog.requests, 2);
      final empty = await _launch(
        cache,
        catalog,
      ).read(catalogControllerProvider.future);
      expect(empty.services, isEmpty);
      expect(empty.errorCode, isNull);
      expect(catalog.requests, 2);
    },
  );

  test(
    'stale services render before a shared refresh and survive an offline failure',
    () async {
      final cache = _Cache();
      await cache.write(DemoWorkshop.services, DateTime.utc(2000));
      final saved = cache.saved;
      final catalog = _Catalog()..pending = Completer();
      final app = _launch(cache, catalog);
      final initial = await app.read(catalogControllerProvider.future);
      expect(initial.refreshing, isTrue);
      expect(initial.services, DemoWorkshop.services);
      final controller = app.read(catalogControllerProvider.notifier);
      final concurrent = [controller.refreshIfStale(), controller.refresh()];
      expect(catalog.requests, 1);
      catalog.pending!.completeError(const ApiFailure('NETWORK_ERROR'));
      await Future.wait(concurrent);
      await app.pump();
      final offline = app.read(catalogControllerProvider).requireValue;
      expect(offline.errorCode, 'NETWORK_ERROR');
      expect(offline.services, initial.services);
      expect(offline.refreshing, isFalse);
      expect(cache.saved, same(saved));

      catalog.pending = null;
      await controller.refresh();
      expect(
        app.read(catalogControllerProvider).requireValue.errorCode,
        isNull,
      );
      expect(cache.saved!.isFreshAt(DateTime.now()), isTrue);
    },
  );

  test(
    'admin invalidation expires a disk-only catalog and discards an older request',
    () async {
      final cache = _Cache();
      await cache.write(DemoWorkshop.services, DateTime.now());
      final catalog = _Catalog()..pending = Completer();
      final app = _launch(cache, catalog);
      final invalidate = Provider(
        (ref) =>
            () => invalidatePublicCatalog(ref),
      );
      await app.read(invalidate)();
      expect(cache.saved!.isFreshAt(DateTime.now()), isFalse);
      expect(
        (await app.read(catalogControllerProvider.future)).refreshing,
        isTrue,
      );
      expect(catalog.requests, 1);
      final old = catalog.pending!;
      catalog.pending = Completer();
      await app.read(invalidate)();
      await app.read(catalogControllerProvider.future);
      final refresh = app.read(catalogControllerProvider.notifier).refresh();
      catalog.pending!.complete([]);
      await refresh;
      old.complete(DemoWorkshop.services);
      await app.pump();
      expect(catalog.requests, 2);
      expect(cache.saved!.services, isEmpty);
      expect(
        app.read(catalogControllerProvider).requireValue.services,
        isEmpty,
      );
    },
  );
}
