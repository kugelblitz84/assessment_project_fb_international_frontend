import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_theme.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/widgets/service_card.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/home_page.dart';
import 'package:assessment_project_fb_international_frontend/features/home/view/widgets/featured_services_section.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

Map<String, dynamic> serviceJson(String id, {bool featured = false}) => {
  'id': id,
  'name': 'Care $id',
  'description': 'Care for your car, selected by the workshop.',
  'categoryId': 'maintenance',
  'categoryName': 'Maintenance',
  'price': 650,
  'currency': 'BDT',
  'durationMinutes': 45,
  'available': true,
  'inclusions': <String>[],
  'type': id == 'package' ? 'PACKAGE' : 'INDIVIDUAL',
  'isFeatured': featured,
};

class FeaturedCatalog extends ServiceCatalogService {
  FeaturedCatalog() : super(Dio());
  List<ServiceModel> items = [
    ServiceModel.fromJson(serviceJson('wash', featured: true)),
    ServiceModel.fromJson(serviceJson('oil')),
    ServiceModel.fromJson(serviceJson('package', featured: true)),
  ];
  Completer<List<ServiceModel>>? pending;
  bool fail = false;
  int requests = 0;

  @override
  Future<List<ServiceModel>> getServices() async {
    requests++;
    if (fail) throw const ApiFailure('NETWORK_ERROR');
    return pending?.future ?? items;
  }
}

ProviderContainer containerFor(FeaturedCatalog service) =>
    ProviderContainer.test(
      overrides: [
        serviceCatalogProvider.overrideWithValue(service),
        currentUserProvider.overrideWithValue(null),
      ],
    );

Future<GoRouter> launch(
  WidgetTester tester,
  ProviderContainer container, {
  bool sectionOnly = false,
}) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => Scaffold(
          body: sectionOnly
              ? const CustomScrollView(slivers: [FeaturedServicesSection()])
              : const HomePage(),
        ),
      ),
      GoRoute(
        name: AppRoutes.serviceDetails,
        path: AppRoutes.serviceDetailsPath,
        builder: (_, state) => Scaffold(
          body: Text('Details: ${state.pathParameters['serviceId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (_, _) =>
            MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  test('service DTO preserves featured flags and rejects invalid flags', () {
    for (final flag in [true, false]) {
      expect(
        ServiceModel.fromJson(serviceJson('wash', featured: flag)).isFeatured,
        flag,
      );
    }
    final legacy = serviceJson('wash')..remove('isFeatured');
    expect(ServiceModel.fromJson(legacy).isFeatured, isFalse);
    for (final invalid in [null, 'true', 1]) {
      expect(
        () => ServiceModel.fromJson({...legacy, 'isFeatured': invalid}),
        throwsFormatException,
      );
    }
  });

  test(
    'featured projection shares catalogue requests and tracks refreshes',
    () async {
      final service = FeaturedCatalog();
      final container = containerFor(service);
      container.listen(featuredServicesProvider, (_, _) {});
      await container.read(catalogControllerProvider.future);
      expect(container.read(featuredServicesProvider).map((s) => s.id), [
        'wash',
        'package',
      ]);
      expect(service.requests, 1);
      service.fail = true;
      await container.read(catalogControllerProvider.notifier).refresh();
      expect(container.read(featuredServicesProvider), hasLength(2));
      service.fail = false;
      service.items = [
        ServiceModel.fromJson(serviceJson('oil', featured: true)),
      ];
      await container.read(catalogControllerProvider.notifier).refresh();
      expect(container.read(featuredServicesProvider).single.id, 'oil');
      service.items = [];
      container.invalidate(catalogControllerProvider);
      await container.read(catalogControllerProvider.future);
      expect(container.read(featuredServicesProvider), isEmpty);
    },
  );

  testWidgets(
    'loading and failed catalogues do not show an empty featured section',
    (tester) async {
      final service = FeaturedCatalog()
        ..pending = Completer<List<ServiceModel>>();
      final container = containerFor(service);
      final request = container.read(catalogControllerProvider.future);
      await launch(tester, container, sectionOnly: true);
      expect(find.text('Featured services'), findsNothing);
      service.pending!.completeError(const ApiFailure('NETWORK_ERROR'));
      await request;
      await tester.pumpAndSettle();
      expect(find.text('Featured services'), findsNothing);
      service.pending = null;
      await container.read(catalogControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Featured services'), findsOneWidget);
    },
  );

  testWidgets(
    'home hides featured content during search and category filtering',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final service = FeaturedCatalog();
      final container = containerFor(service);
      await launch(tester, container);
      expect(find.text('Featured services'), findsOneWidget);
      expect(service.requests, 1);
      final cards = tester
          .widgetList<ServiceCard>(find.byType(ServiceCard))
          .toList();
      expect(cards.take(2).map((card) => card.service.id), ['wash', 'package']);
      final controller = container.read(homeControllerProvider.notifier);
      controller.search('oil');
      await tester.pumpAndSettle();
      expect(find.text('Featured services'), findsNothing);
      expect(find.text('Search results'), findsOneWidget);
      controller.clear();
      await tester.pumpAndSettle();
      expect(find.text('Featured services'), findsOneWidget);
      controller.category('maintenance');
      await tester.pumpAndSettle();
      expect(find.text('Featured services'), findsNothing);
      controller.clear();
      service.items = [ServiceModel.fromJson(serviceJson('oil'))];
      await container.read(catalogControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Featured services'), findsNothing);
      expect(find.text('Care for every journey'), findsOneWidget);
    },
  );

  for (final width in [320.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'featured cards fit $width at scale $scale and open details',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 1200);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final container = containerFor(FeaturedCatalog());
          await launch(tester, container, sectionOnly: true);
          await tester.ensureVisible(find.text('FEATURED').first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('FEATURED').first);
          await tester.pumpAndSettle();
          expect(find.text('Details: wash'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
