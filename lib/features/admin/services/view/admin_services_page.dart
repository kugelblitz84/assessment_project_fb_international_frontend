import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/services/controller/admin_service_list_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminServicesPage extends ConsumerWidget {
  const AdminServicesPage({super.key, this.packages = false});
  final bool packages;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminServiceFilterProvider(packages).notifier);
    final path = packages
        ? AppRoutes.adminPackagesPath
        : AppRoutes.adminServicesPath;
    return AdminAsync(
      value: ref.watch(adminServiceListProvider(packages)),
      onRetry: () => ref.invalidate(adminServicesProvider),
      builder: (data) {
        final items = data.items;
        final categories = data.categories;
        return AdminPageBody(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('$path/new'),
                  icon: const Icon(Icons.add),
                  label: Text(packages ? 'Create package' : 'Add service'),
                ),
                OutlinedButton(
                  onPressed: () => ref.invalidate(adminServicesProvider),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.search,
            ),
            DropdownButtonFormField<String>(
              initialValue: data.filter.category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('All categories'),
                ),
                for (final entry in categories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: controller.category,
            ),
            DropdownButtonFormField<String>(
              initialValue: data.filter.active,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('All statuses')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: controller.active,
            ),
            if (items.isEmpty) const AdminEmpty(),
            for (final item in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: item.service.imageUrl == null
                            ? const Icon(Icons.car_repair_outlined)
                            : Image.network(
                                item.service.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.service.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(item.service.categoryName),
                            Text(
                              '${Formatters.price(item.service.price, item.service.currency)} · ${Formatters.duration(item.service.durationMinutes)}',
                            ),
                            Text(
                              '${item.isActive ? 'Active' : 'Inactive'}${item.isFeatured ? ' · Featured' : ''}',
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => context.go(
                                    AppRoutes.adminEditLocation(path, item.id),
                                  ),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed:
                                      ref.watch(
                                        adminServiceMutationProvider.select(
                                          (state) => state.busy,
                                        ),
                                      )
                                      ? null
                                      : () async {
                                          if (!await adminConfirm(
                                                context,
                                                '${item.isActive ? 'Deactivate' : 'Activate'} item?',
                                                'This changes customer catalog visibility.',
                                              ) ||
                                              !context.mounted) {
                                            return;
                                          }
                                          final result = await ref
                                              .read(
                                                adminServiceMutationProvider
                                                    .notifier,
                                              )
                                              .setActive(
                                                item.id,
                                                !item.isActive,
                                              );
                                          if (context.mounted) {
                                            adminNotice(context, result);
                                          }
                                        },
                                  child: Text(
                                    item.isActive ? 'Deactivate' : 'Activate',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}
