import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../../shared/model/appointment_model.dart';
import '../../../shared/view/booking_status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});
  final AppointmentModel booking;
  @override
  Widget build(BuildContext context) => Card(
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
              BookingStatusBadge(status: booking.status),
            ],
          ),
          SizedBox(height: AppSize.vertical(16)),
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
