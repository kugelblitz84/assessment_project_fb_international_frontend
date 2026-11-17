import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../shared/controller/admin_providers.dart';
import '../../shared/view/admin_widgets.dart';

class AdminServicesPage extends ConsumerStatefulWidget {
  const AdminServicesPage({super.key, this.packages = false});
  final bool packages;
  @override
  ConsumerState<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends ConsumerState<AdminServicesPage> {
  String search = '', category = '', active = '';
  @override
  Widget build(BuildContext context) {
    final path = widget.packages
        ? AppRoutes.adminPackagesPath
        : AppRoutes.adminServicesPath;
    return AdminAsync(
      value: ref.watch(adminServicesProvider(ref.watch(adminOwnerProvider))),
      onRetry: () => ref.invalidate(adminServicesProvider),
      builder: (all) {
        final items = all
            .where(
              (item) =>
                  item.service.isPackage == widget.packages &&
                  (category.isEmpty || item.service.categoryId == category) &&
                  (active.isEmpty || item.isActive == (active == 'active')) &&
                  '${item.service.name} ${item.service.description}'
                      .toLowerCase()
                      .contains(search.toLowerCase()),
            )
            .toList();
        final categories = {
          for (final item in all)
            item.service.categoryId: item.service.categoryName,
        };
        return AdminPageBody(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('$path/new'),
                  icon: const Icon(Icons.add),
                  label: Text(
                    widget.packages ? 'Create package' : 'Add service',
                  ),
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
              onChanged: (v) => setState(() => search = v),
            ),
            DropdownButtonFormField<String>(
              initialValue: category,
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
              onChanged: (v) => setState(() => category = v ?? ''),
            ),
            DropdownButtonFormField<String>(
              initialValue: active,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('All statuses')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => active = v ?? ''),
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
                                  onPressed: ref.watch(adminMutationProvider)
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
                                                adminMutationProvider.notifier,
                                              )
                                              .save(
                                                ApiEndpoints.adminServices,
                                                {'isActive': !item.isActive},
                                                id: item.id,
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
