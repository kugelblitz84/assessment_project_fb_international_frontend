import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../model/appointment_model.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});
  final BookingStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, icon, color, background) = switch (status) {
      BookingStatus.pending => (
        'Pending',
        Icons.schedule,
        AppColors.pending,
        AppColors.pendingSoft,
      ),
      BookingStatus.confirmed => (
        'Confirmed',
        Icons.check_circle_outline,
        AppColors.success,
        AppColors.successSoft,
      ),
      BookingStatus.cancelled => (
        'Cancelled',
        Icons.cancel_outlined,
        AppColors.error,
        AppColors.errorSoft,
      ),
      BookingStatus.completed => (
        'Completed',
        Icons.task_alt,
        AppColors.secondary,
        const Color(0xFFEEF2F6),
      ),
    };
    return Semantics(
      label: 'Booking status: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
