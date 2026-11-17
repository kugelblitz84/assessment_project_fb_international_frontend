import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

class PaymentActions extends ConsumerWidget {
  const PaymentActions({super.key, required this.appointment});
  final AppointmentModel appointment;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(demoModeProvider)
      ? const Text('Demo: pay at workshop')
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              '/bookings/${Uri.encodeComponent(appointment.id)}/payment',
            ),
            icon: const Icon(Icons.payments_outlined),
            label: Text(
              appointment.canPayOnline
                  ? 'Payment options • Pay Online / Pay at Workshop'
                  : 'Payment status and history',
            ),
          ),
        );
}
