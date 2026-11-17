import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/appointments_controller.dart';
import '../../shared/view/appointment_info.dart';
import '../../shared/view/booking_status_badge.dart';

class BookingDetailsPage extends ConsumerWidget {
  const BookingDetailsPage({super.key, required this.bookingId});
  final String bookingId;
  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this appointment?'),
        content: const Text(
          'This will cancel your pending booking request. You can browse services to book another time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel appointment'),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
        ],
      ),
    );
    if (cancel != true || !context.mounted) return;
    final success = await ref
        .read(appointmentDetailsProvider(bookingId).notifier)
        .cancel();
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(appointmentDetailsProvider(bookingId));
    final user = ref.watch(currentUserProvider);
    return AdaptiveAppShell(
      title: 'Booking details',
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 760,
          child: details.when(
            loading: () => const LoadingState(label: 'Loading appointment…'),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Appointment details',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                booking.serviceName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              BookingStatusBadge(status: booking.status),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          AppointmentInfo(appointment: booking),
                          if (data.errorCode != null) ...[
                            const SizedBox(height: 16),
                            InlineNotice(
                              message: ApiErrorHandler.messageFor(
                                data.errorCode,
                              ),
                              error: true,
                            ),
                          ],
                          if (booking.canCancel) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Pending requests can be cancelled here.',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              onPressed: data.busy
                                  ? null
                                  : () => _cancel(context, ref),
                              icon: data.busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cancel_outlined),
                              label: Text(
                                data.busy
                                    ? 'Cancelling…'
                                    : 'Cancel appointment',
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: data.busy
                                ? null
                                : () => ref.invalidate(
                                    appointmentDetailsProvider(bookingId),
                                  ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh appointment'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.goNamed(AppRoutes.myBookings),
                    child: const Text('Back to My Bookings'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
