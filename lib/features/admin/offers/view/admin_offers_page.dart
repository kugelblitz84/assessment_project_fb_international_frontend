import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../routes/app_routes.dart';
import '../../shared/controller/admin_providers.dart';
import '../../shared/model/admin_models.dart';
import '../../shared/view/admin_widgets.dart';

class AdminOffersPage extends ConsumerWidget {
  const AdminOffersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsync(
    value: ref.watch(adminOffersProvider(ref.watch(adminOwnerProvider))),
    onRetry: () => ref.invalidate(adminOffersProvider),
    builder: (items) {
      final services =
          ref
              .watch(adminServicesProvider(ref.watch(adminOwnerProvider)))
              .asData
              ?.value ??
          [];
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
                    Text(
                      services
                              .where((s) => s.id == item.serviceId)
                              .firstOrNull
                              ?.service
                              .name ??
                          item.serviceId,
                    ),
                    Text(
                      '${item.discountValue}${item.discountType == 'PERCENTAGE' ? '%' : ' BDT'} · ${item.stateAt(DateTime.now())}',
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
                          onPressed: ref.watch(adminMutationProvider)
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
                                      .read(adminMutationProvider.notifier)
                                      .save(ApiEndpoints.adminOffers, {
                                        'isActive': !item.isActive,
                                      }, id: item.id);
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
