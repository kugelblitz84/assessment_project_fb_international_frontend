import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/appointments_controller.dart';
import '../../shared/model/appointment_model.dart';
import '../../shared/view/appointment_info.dart';
import '../../shared/view/booking_status_badge.dart';

class BookingConfirmationPage extends ConsumerWidget {
  const BookingConfirmationPage({super.key, required this.bookingId});
  final String bookingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(appointmentDetailsProvider(bookingId));
    final user = ref.watch(currentUserProvider);
    return AdaptiveAppShell(
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
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                            size: 44,
                            color: confirmed
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        booking.status == BookingStatus.pending
                            ? 'Your request is saved. Check My Bookings for its current status.'
                            : 'You can find all the details in My Bookings.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.secondary),
                      ),
                      const SizedBox(height: 20),
                      Center(child: BookingStatusBadge(status: booking.status)),
                      const SizedBox(height: 24),
                      const Divider(),
                      AppointmentInfo(appointment: booking),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.goNamed(AppRoutes.myBookings),
                        child: const Text('View my bookings'),
                      ),
                      const SizedBox(height: 8),
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
