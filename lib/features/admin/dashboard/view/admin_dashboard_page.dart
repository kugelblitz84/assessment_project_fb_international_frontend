import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/controller/admin_dashboard_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsync(
    value: ref.watch(adminDashboardProvider(ref.watch(adminOwnerProvider))),
    onRetry: () => ref.invalidate(adminDashboardProvider),
    builder: (data) => AdminPageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Workshop overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: () => ref.invalidate(adminDashboardProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (count, label) in [
                (data.totalServices, 'Services'),
                (data.activeServices, 'Active services'),
                (data.totalCategories, 'Categories'),
                (data.totalPackages, 'Packages'),
                (data.activeOffers, 'Active offers'),
                (data.pendingAppointments, 'Pending appointments'),
                (data.confirmedAppointments, 'Confirmed appointments'),
                (data.completedAppointments, 'Completed appointments'),
              ])
                SizedBox(
                  width: constraints.maxWidth < 440
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label),
                          const SizedBox(height: 8),
                          Text(
                            '$count',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (path, label) in const [
              ('${AppRoutes.adminServicesPath}/new', 'Add service'),
              ('${AppRoutes.adminCategoriesPath}/new', 'Add category'),
              ('${AppRoutes.adminPackagesPath}/new', 'Create package'),
              ('${AppRoutes.adminOffersPath}/new', 'Create offer'),
              (
                '${AppRoutes.adminAppointmentsPath}?status=pending',
                'View pending appointments',
              ),
            ])
              OutlinedButton(
                onPressed: () => context.go(path),
                child: Text(label),
              ),
          ],
        ),
      ],
    ),
  );
}
