import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../model/appointment_model.dart';

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
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 21, color: AppColors.secondary),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
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
