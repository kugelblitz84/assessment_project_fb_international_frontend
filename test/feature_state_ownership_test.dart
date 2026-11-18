import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/session/presentation/controller/session_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/categories/controller/category_form_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/controller/offer_form_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/service_form_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/model/admin_service.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';

import 'support/admin_fakes.dart' as admin;
import 'support/demo_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'controller rejects date-picker results after draft invalidation',
    () async {
      final container = demoContainer();
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('exterior-wash');
      container.listen(provider, (_, _) {});
      final original = await container.read(provider.future);
      final controller = container.read(provider.notifier);
      final selection = controller.prepareDateSelection()!;
      container.invalidate(provider);
      await container.read(provider.future);
      await controller.selectDate(
        original.date.add(const Duration(days: 2)),
        selection: selection,
      );
      expect(container.read(provider).requireValue.date, original.date);
      expect(container.read(provider).requireValue.loadingSlots, isFalse);
    },
  );

  test(
    'controller rejects dates outside its configured booking horizon',
    () async {
      final container = demoContainer();
      await container.read(sessionProvider.future);
      final provider = bookingControllerProvider('exterior-wash');
      container.listen(provider, (_, _) {});
      final original = await container.read(provider.future);
      final controller = container.read(provider.notifier);
      await controller.selectDate(
        controller.lastBookableDate.add(const Duration(days: 1)),
      );
      expect(container.read(provider).requireValue, same(original));
    },
  );

  test(
    'category controller rejects invalid numeric input without a widget form',
    () async {
      final adapter = admin.AdminAdapter();
      final container = admin.adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final provider = categoryFormProvider((
        image: (owner: Object(), initialUrl: null),
        item: null,
      ));
      container.listen(provider, (_, _) {});
      expect(
        await container
            .read(provider.notifier)
            .save(
              name: 'Care',
              slug: '',
              description: '',
              sortOrder: 'invalid',
            ),
        isNull,
      );
      expect(container.read(provider).error, isNotNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
    },
  );

  test(
    'offer drafts are isolated and controller validates cross-field input',
    () async {
      final adapter = admin.AdminAdapter();
      final container = admin.adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final first = offerFormProvider((
        owner: Object(),
        item: null,
        firstServiceId: admin.serviceId,
      ));
      final second = offerFormProvider((
        owner: Object(),
        item: null,
        firstServiceId: admin.serviceId,
      ));
      container.listen(first, (_, _) {});
      container.listen(second, (_, _) {});
      final controller = container.read(first.notifier);
      controller.setActive(false);
      expect(container.read(first).active, isFalse);
      expect(container.read(second).active, isTrue);
      expect(
        await controller.save(
          title: 'Offer',
          description: '',
          value: '150',
          start: '2026-11-20 09:00',
          end: '2026-11-21 09:00',
        ),
        isNull,
      );
      expect(container.read(first).error, 'Percentage must be at most 100.');
      expect(container.read(second).error, isNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
    },
  );

  test(
    'package controller owns selection, quantities, and validation',
    () async {
      final adapter = admin.AdminAdapter();
      final container = admin.adminContainer(adapter: adapter);
      await container.read(sessionProvider.future);
      final provider = serviceFormProvider((
        image: (owner: Object(), initialUrl: null),
        item: null,
        package: true,
        firstCategoryId: admin.categoryId,
        individuals: [AdminService.fromJson(admin.serviceJson())],
      ));
      container.listen(provider, (_, _) {});
      final controller = container.read(provider.notifier);
      controller.addItem('unknown');
      expect(container.read(provider).quantities, isEmpty);
      controller.addItem(admin.serviceId);
      controller.updateQuantity(admin.serviceId, '0');
      expect(controller.remaining, isEmpty);
      expect(
        await controller.save(
          name: 'Package',
          slug: '',
          description: '',
          price: '500',
          duration: '30',
          sortOrder: '0',
        ),
        isNull,
      );
      expect(container.read(provider).error, isNotNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
      await container.read(sessionProvider.notifier).logout();
      expect(container.read(provider).quantities, isEmpty);
    },
  );
}
