import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/controller/admin_appointment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/controller/appointment_filter_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_time.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class AdminAppointmentsPage extends ConsumerWidget {
  const AdminAppointmentsPage({super.key, this.initialStatus});
  final String? initialStatus;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(appointmentFilterProvider(initialStatus));
    final controller = ref.read(
      appointmentFilterProvider(initialStatus).notifier,
    );
    final date = filter.date;
    final provider = adminAppointmentsProvider((
      owner: ref.watch(adminOwnerProvider),
      filter: filter.query,
    ));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: filter.status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All statuses'),
                  ),
                  for (final s in BookingStatus.values)
                    DropdownMenuItem(value: s.name, child: Text(s.name)),
                ],
                onChanged: controller.selectStatus,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      date == null
                          ? 'Filter date (Asia/Dhaka)'
                          : Formatters.date(date),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.pickerInitialDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && context.mounted) {
                        controller.selectDate(picked);
                      }
                    },
                  ),
                  if (date != null)
                    TextButton(
                      onPressed: () => controller.selectDate(null),
                      child: const Text('Clear date'),
                    ),
                  IconButton(
                    tooltip: 'Refresh appointments',
                    onPressed: () => ref.invalidate(provider),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminAsync(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            builder: (items) => AdminPageBody(
              children: [
                if (items.isEmpty) const AdminEmpty(),
                for (final item in items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.customerName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(item.serviceName),
                          Text('Payment: ${item.paymentStatus.label}'),
                          Text(
                            '${WorkshopTime.input(item.startsAt)} (Asia/Dhaka)',
                          ),
                          Text(
                            '${item.status.name} · ${Formatters.price(item.price, item.currency)}',
                          ),
                          TextButton(
                            onPressed: () => context.go(
                              '${AppRoutes.adminAppointmentsPath}/${Uri.encodeComponent(item.id)}',
                            ),
                            child: const Text('Details'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
