import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

class DetailLine extends StatelessWidget {
  const DetailLine({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSize.vertical(10)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.icon(21), color: AppColors.secondary),
          SizedBox(width: AppSize.horizontal(12)),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: AppSize.font(13),
                ),
              ),
              SizedBox(height: AppSize.vertical(3)),
              SelectableText(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AppointmentInfo extends StatelessWidget {
  const AppointmentInfo({super.key, required this.appointment});
  final AppointmentModel appointment;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DetailLine(
        label: 'Payment status',
        value: appointment.paymentStatus.label,
        icon: Icons.payments_outlined,
      ),
      if (appointment.paymentMethod != null)
        DetailLine(label: 'Payment method', value: appointment.paymentMethod!),
      DetailLine(
        label: 'Booking reference',
        value: appointment.id,
        icon: Icons.tag,
      ),
      DetailLine(
        label: 'Service',
        value: appointment.serviceName,
        icon: Icons.car_repair_outlined,
      ),
      DetailLine(
        label: 'Date',
        value: Formatters.date(appointment.slot.workshopTime),
        icon: Icons.calendar_month_outlined,
      ),
      DetailLine(
        label: 'Time',
        value:
            '${Formatters.time(appointment.slot.workshopTime)}\n${appointment.slot.timeZone}',
        icon: Icons.schedule_outlined,
      ),
      DetailLine(
        label: 'Duration',
        value: Formatters.duration(appointment.durationMinutes),
        icon: Icons.timelapse,
      ),
      const Divider(),
      DetailLine(
        label: 'Service price',
        value: Formatters.price(appointment.price, appointment.currency),
        icon: Icons.receipt_long_outlined,
      ),
    ],
  );
}
