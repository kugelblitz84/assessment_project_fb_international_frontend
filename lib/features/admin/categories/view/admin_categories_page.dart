import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/categories/controller/admin_category_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsync(
    value: ref.watch(adminCategoriesProvider(ref.watch(adminOwnerProvider))),
    onRetry: () => ref.invalidate(adminCategoriesProvider),
    builder: (items) => AdminPageBody(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  context.go('${AppRoutes.adminCategoriesPath}/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add category'),
            ),
            OutlinedButton(
              onPressed: () => ref.invalidate(adminCategoriesProvider),
              child: const Text('Refresh'),
            ),
          ],
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
                    child: item.imageUrl == null
                        ? const Icon(Icons.category_outlined)
                        : Image.network(
                            item.imageUrl!,
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
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(item.slug),
                        Text(
                          '${item.isActive ? 'Active' : 'Inactive'} · Order ${item.sortOrder}',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => context.go(
                                AppRoutes.adminEditLocation(
                                  AppRoutes.adminCategoriesPath,
                                  item.id,
                                ),
                              ),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed:
                                  ref.watch(adminCategoryMutationProvider)
                                  ? null
                                  : () async {
                                      if (!await adminConfirm(
                                            context,
                                            '${item.isActive ? 'Deactivate' : 'Activate'} category?',
                                            'This changes category and related catalog visibility.',
                                          ) ||
                                          !context.mounted) {
                                        return;
                                      }
                                      final result = await ref
                                          .read(
                                            adminCategoryMutationProvider
                                                .notifier,
                                          )
                                          .setActive(item.id, !item.isActive);
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
    ),
  );
}
