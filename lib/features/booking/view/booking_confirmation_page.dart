import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/app/shell/page_scaffold.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/current_user_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/page_container.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/controller/appointments_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/view/widgets/appointment_info.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/view/widgets/booking_status_badge.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/view/payment_actions.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class BookingConfirmationPage extends ConsumerWidget {
  const BookingConfirmationPage({super.key, required this.bookingId});
  final String bookingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(appointmentDetailsProvider(bookingId));
    final user = ref.watch(currentUserProvider);
    return AppPageScaffold(
      title: 'Booking acknowledgement',
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 660,
          child: details.when(
            loading: () => const LoadingState(label: 'Loading your booking…'),
            error: (_, _) => ErrorState(
              onRetry: () =>
                  ref.invalidate(appointmentDetailsProvider(bookingId)),
            ),
            data: (data) {
              if (user == null || data.ownerId != user.id) {
                return const LoadingState();
              }
              final booking = data.appointment;
              if (booking == null) {
                return ErrorState(
                  code: data.errorCode,
                  onRetry: () =>
                      ref.invalidate(appointmentDetailsProvider(bookingId)),
                );
              }
              final confirmed = booking.status == BookingStatus.confirmed;
              final headline = switch (booking.status) {
                BookingStatus.pending => 'Booking request received',
                BookingStatus.confirmed => 'Appointment confirmed',
                BookingStatus.cancelled => 'Appointment cancelled',
                BookingStatus.completed => 'Service completed',
              };
              return AppSurface(
                child: Padding(
                  padding: AppSize.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSize.vertical(8)),
                      Center(
                        child: Container(
                          padding: AppSize.inset(20),
                          decoration: BoxDecoration(
                            color: confirmed
                                ? AppColors.successSoft
                                : AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            confirmed
                                ? Icons.check_circle_outline
                                : Icons.event_available_outlined,
                            size: AppSize.icon(44),
                            color: confirmed
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.vertical(24)),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: AppSize.vertical(12)),
                      Text(
                        booking.status == BookingStatus.pending
                            ? 'Your request is saved. Check My Bookings for its current status.'
                            : 'You can find all the details in My Bookings.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.secondary),
                      ),
                      SizedBox(height: AppSize.vertical(20)),
                      Center(child: BookingStatusBadge(status: booking.status)),
                      SizedBox(height: AppSize.vertical(24)),
                      const Divider(),
                      AppointmentInfo(appointment: booking),
                      PaymentActions(appointment: booking),
                      SizedBox(height: AppSize.vertical(24)),
                      FilledButton(
                        onPressed: () => context.goNamed(AppRoutes.myBookings),
                        child: const Text('View my bookings'),
                      ),
                      SizedBox(height: AppSize.vertical(8)),
                      TextButton(
                        onPressed: () => context.goNamed(AppRoutes.home),
                        child: const Text('Back to Explore'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
