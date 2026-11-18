import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/offers/controller/admin_offer_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_time.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminOffersPage extends ConsumerWidget {
  const AdminOffersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsync(
    value: ref.watch(adminOffersProvider(ref.watch(adminOwnerProvider))),
    onRetry: () => ref.invalidate(adminOffersProvider),
    builder: (items) {
      final serviceNames = ref.watch(adminServiceNamesProvider);
      return AdminPageBody(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('${AppRoutes.adminOffersPath}/new'),
                icon: const Icon(Icons.add),
                label: const Text('Create offer'),
              ),
              OutlinedButton(
                onPressed: () => ref.invalidate(adminOffersProvider),
                child: const Text('Refresh'),
              ),
            ],
          ),
          if (items.isEmpty) const AdminEmpty(),
          for (final item in items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(serviceNames[item.serviceId] ?? item.serviceId),
                    Text(
                      '${item.discountValue}${item.discountType == 'PERCENTAGE' ? '%' : ' BDT'} · ${ref.watch(adminOfferStatusProvider(item))}',
                    ),
                    Text(
                      '${WorkshopTime.input(item.startsAt)} – ${WorkshopTime.input(item.endsAt)} (Asia/Dhaka)',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => context.go(
                            AppRoutes.adminEditLocation(
                              AppRoutes.adminOffersPath,
                              item.id,
                            ),
                          ),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed:
                              ref.watch(
                                adminOfferMutationProvider.select(
                                  (state) => state.busy,
                                ),
                              )
                              ? null
                              : () async {
                                  if (!await adminConfirm(
                                        context,
                                        '${item.isActive ? 'Disable' : 'Enable'} offer?',
                                        'This changes eligibility for backend pricing.',
                                      ) ||
                                      !context.mounted) {
                                    return;
                                  }
                                  final result = await ref
                                      .read(adminOfferMutationProvider.notifier)
                                      .setActive(item.id, !item.isActive);
                                  if (context.mounted) {
                                    adminNotice(context, result);
                                  }
                                },
                          child: Text(item.isActive ? 'Disable' : 'Enable'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
