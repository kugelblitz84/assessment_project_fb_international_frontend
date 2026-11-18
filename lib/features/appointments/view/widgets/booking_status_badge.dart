import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/responsive/adaptive_layout.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({
    super.key,
    required this.status,
    this.isUpcoming = false,
  });
  final BookingStatus status;
  final bool isUpcoming;
  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width <= AppBreakpoints.compactMaxWidth;
    final (label, icon, color, background) = switch (status) {
      BookingStatus.pending => (
        isUpcoming ? 'Upcoming' : 'Pending',
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
        AppColors.surfaceRecessed,
      ),
    };
    return Semantics(
      label: 'Booking status: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(mobile ? 8 : 12),
            vertical: AppSize.vertical(mobile ? 5 : 8),
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSize.radius(8)),
          ),
          child: Wrap(
            spacing: mobile ? 4 : 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, size: AppSize.icon(mobile ? 14 : 16), color: color),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: AppSize.font(mobile ? 11 : 13),
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
