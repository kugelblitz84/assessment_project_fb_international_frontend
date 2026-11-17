import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/appointments_controller.dart';
import '../../shared/model/appointment_model.dart';
import '../../shared/view/booking_status_badge.dart';
import '../controller/my_bookings_controller.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(appointmentsControllerProvider);
    final tab = ref.watch(myBookingsTabProvider);
    final user = ref.watch(currentUserProvider);
    return AdaptiveAppShell(
      primary: true,
      title: 'My bookings',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(appointmentsControllerProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PageContainer(
            maxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your car’s care, all in one place.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep track of upcoming appointments and past visits.',
                  style: TextStyle(color: AppColors.secondary),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in BookingsTab.values)
                      ChoiceChip(
                        label: Text(
                          item == BookingsTab.upcoming
                              ? 'Upcoming'
                              : 'Previous',
                        ),
                        selected: tab == item,
                        onSelected: (_) => ref
                            .read(myBookingsTabProvider.notifier)
                            .select(item),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                bookings.when(
                  loading: () =>
                      const LoadingState(label: 'Loading your appointments…'),
                  error: (_, _) => ErrorState(
                    onRetry: () =>
                        ref.invalidate(appointmentsControllerProvider),
                  ),
                  data: (data) {
                    if (user == null || data.ownerId != user.id) {
                      return const LoadingState();
                    }
                    if (data.errorCode != null && data.items.isEmpty) {
                      return ErrorState(
                        code: data.errorCode,
                        onRetry: () => ref
                            .read(appointmentsControllerProvider.notifier)
                            .refresh(),
                      );
                    }
                    final items =
                        data.items
                            .where(
                              (a) => tab == BookingsTab.upcoming
                                  ? a.upcoming
                                  : !a.upcoming,
                            )
                            .toList()
                          ..sort(
                            (a, b) => tab == BookingsTab.upcoming
                                ? a.slot.startsAt.compareTo(b.slot.startsAt)
                                : b.slot.startsAt.compareTo(a.slot.startsAt),
                          );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: data.refreshing
                                ? null
                                : () => ref
                                      .read(
                                        appointmentsControllerProvider.notifier,
                                      )
                                      .refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ),
                        if (data.refreshing) const LinearProgressIndicator(),
                        if (data.errorCode != null) ...[
                          InlineNotice(
                            message:
                                '${ApiErrorHandler.messageFor(data.errorCode)} These appointments may be out of date.',
                            error: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (items.isEmpty)
                          StateMessage(
                            title: tab == BookingsTab.upcoming
                                ? 'No upcoming bookings yet'
                                : 'No previous bookings',
                            message: tab == BookingsTab.upcoming
                                ? 'A little care goes a long way. Find your next service.'
                                : 'Your previous bookings will appear here.',
                            icon: Icons.event_note_outlined,
                            action: FilledButton(
                              onPressed: () => context.goNamed(AppRoutes.home),
                              child: const Text('Explore services'),
                            ),
                          ),
                        for (final booking in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _BookingCard(booking: booking),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final AppointmentModel booking;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          Text(
            booking.slot.timeZone,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                Formatters.price(booking.price, booking.currency),
                style: const TextStyle(
                  fontSize: 22,
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
