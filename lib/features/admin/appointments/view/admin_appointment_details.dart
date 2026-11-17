import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/appointments/controller/admin_appointment_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/view/admin_widgets.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_time.dart';

class AdminAppointmentDetails extends ConsumerStatefulWidget {
  const AdminAppointmentDetails({super.key, required this.id});
  final String id;
  @override
  ConsumerState<AdminAppointmentDetails> createState() =>
      _AdminAppointmentDetailsState();
}

class _AdminAppointmentDetailsState
    extends ConsumerState<AdminAppointmentDetails> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminAppointmentProvider((
      owner: ref.watch(adminOwnerProvider),
      id: widget.id,
    ));
    return AdminAsync(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (item) => AdminPageBody(
        children: [
          Text(
            item.serviceName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SelectableText('Appointment ${item.id}'),
          Text('Customer: ${item.customerName}'),
          Text('Email: ${item.customerEmail}'),
          Text('Start: ${WorkshopTime.input(item.startsAt)} (Asia/Dhaka)'),
          Text('End: ${WorkshopTime.input(item.endsAt)} (Asia/Dhaka)'),
          Text('Status: ${item.status.name}'),
          Text('Payment: ${item.paymentStatus.label}'),
          Text('Payment method: ${item.paymentMethod ?? 'None'}'),
          Text('Duration: ${Formatters.duration(item.durationMinutes)}'),
          Text('Charged price: ${Formatters.price(item.price, item.currency)}'),
          Text(
            'Original price: ${Formatters.price(item.basePrice, item.currency)}',
          ),
          Text('Created: ${WorkshopTime.input(item.createdAt)} (Asia/Dhaka)'),
          if (item.cancelledAt != null)
            Text(
              'Cancelled: ${WorkshopTime.input(item.cancelledAt!)} (Asia/Dhaka)',
            ),
          if (item.appliedOfferId != null)
            SelectableText('Applied offer: ${item.appliedOfferId}'),
          if (item.vehicle != null)
            Text(
              'Vehicle: ${item.vehicle!['make']} ${item.vehicle!['model']} ${item.vehicle!['year'] ?? ''}\nRegistration: ${item.vehicle!['registrationNumber'] ?? 'Not supplied'}',
            ),
          if (item.status == BookingStatus.confirmed &&
              DateTime.now().isBefore(item.endsAt))
            const Text(
              'Completion becomes available after the appointment ends. The server verifies all transitions.',
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final action in item.actionsAt(DateTime.now()))
                FilledButton(
                  onPressed: ref.watch(adminAppointmentMutationProvider)
                      ? null
                      : () async {
                          if (!await adminConfirm(
                                context,
                                'Mark appointment ${action.name}?',
                                'Change the status for ${item.customerName} to ${action.name}?',
                              ) ||
                              !context.mounted) {
                            return;
                          }
                          final result = await ref
                              .read(adminAppointmentMutationProvider.notifier)
                              .transition(item.id, action);
                          if (context.mounted) {
                            adminNotice(
                              context,
                              result,
                              success: 'Appointment updated.',
                            );
                          }
                        },
                  child: Text(switch (action) {
                    BookingStatus.confirmed => 'Confirm',
                    BookingStatus.cancelled => 'Cancel',
                    _ => 'Complete',
                  }),
                ),
              OutlinedButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Refresh details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
