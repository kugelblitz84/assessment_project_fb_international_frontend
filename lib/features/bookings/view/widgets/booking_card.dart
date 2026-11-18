import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/view/widgets/booking_status_badge.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});
  final AppointmentModel booking;
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Padding(
      padding: AppSize.inset(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                booking.serviceName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              BookingStatusBadge(
                status: booking.status,
                isUpcoming: booking.upcoming,
              ),
            ],
          ),
          SizedBox(height: AppSize.vertical(16)),
          Text('Payment: ${booking.paymentStatus.label}'),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              Text(
                Formatters.date(booking.slot.workshopTime),
                style: const TextStyle(color: AppColors.secondary),
              ),
              Text(
                Formatters.time(booking.slot.workshopTime),
                style: const TextStyle(color: AppColors.secondary),
              ),
              Text(
                Formatters.duration(booking.durationMinutes),
                style: const TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
          SizedBox(height: AppSize.vertical(8)),
          Text(
            booking.slot.timeZone,
            style: TextStyle(
              fontSize: AppSize.font(12),
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: AppSize.vertical(16)),
          const Divider(),
          SizedBox(height: AppSize.vertical(8)),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                Formatters.price(booking.price, booking.currency),
                style: TextStyle(
                  fontSize: AppSize.font(22),
                  fontWeight: FontWeight.w700,
                ),
              ),
              OutlinedButton(
                onPressed: () => context.pushNamed(
                  AppRoutes.bookingDetails,
                  pathParameters: {'bookingId': booking.id},
                ),
                child: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
