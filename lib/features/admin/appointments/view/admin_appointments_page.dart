import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../../shared/model/appointment_model.dart';
import '../../shared/controller/admin_providers.dart';
import '../../shared/model/admin_models.dart';
import '../../shared/view/admin_widgets.dart';

class AdminAppointmentsPage extends ConsumerStatefulWidget {
  const AdminAppointmentsPage({super.key, this.initialStatus});
  final String? initialStatus;
  @override
  ConsumerState<AdminAppointmentsPage> createState() =>
      _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends ConsumerState<AdminAppointmentsPage> {
  late String status =
      BookingStatus.values.any((s) => s.name == widget.initialStatus)
      ? widget.initialStatus!
      : '';
  DateTime? date;
  @override
  Widget build(BuildContext context) {
    final filter = (
      status: status.isEmpty ? null : status,
      date: date?.toIso8601String().substring(0, 10),
    );
    final provider = adminAppointmentsProvider((
      owner: ref.watch(adminOwnerProvider),
      filter: filter,
    ));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
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
                onChanged: (v) => setState(() => status = v ?? ''),
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
                          : Formatters.date(date!),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? WorkshopTime.local(DateTime.now()),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => date = picked);
                      }
                    },
                  ),
                  if (date != null)
                    TextButton(
                      onPressed: () => setState(() => date = null),
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
