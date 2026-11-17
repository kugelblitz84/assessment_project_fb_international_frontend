import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/appointments_controller.dart';
import '../controller/my_bookings_controller.dart';
import 'widgets/booking_card.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(appointmentsControllerProvider);
    final tab = ref.watch(myBookingsTabProvider);
    final items = ref.watch(visibleAppointmentsProvider);
    final controller = ref.watch(appointmentsControllerProvider.notifier);
    final refresh = controller.refresh;
    Widget box(Widget child) => SliverToBoxAdapter(child: child);
    return RefreshIndicator(
      onRefresh: refresh,
      child: PageSliverScrollView(
        key: const PageStorageKey('bookings-scroll'),
        maxWidth: 960,
        slivers: [
          box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your car’s care, all in one place.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: AppSize.vertical(8)),
                const Text(
                  'Keep track of upcoming appointments and past visits.',
                  style: TextStyle(color: AppColors.secondary),
                ),
                SizedBox(height: AppSize.vertical(24)),
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
                SizedBox(height: AppSize.vertical(24)),
              ],
            ),
          ),
          bookings.when(
            loading: () =>
                box(const LoadingState(label: 'Loading your appointments...')),
            error: (_, _) => box(
              ErrorState(
                onRetry: () => ref.invalidate(appointmentsControllerProvider),
              ),
            ),
            data: (data) {
              if (data.ownerId == null) return box(const LoadingState());
              if (data.errorCode != null && data.items.isEmpty) {
                return box(ErrorState(code: data.errorCode, onRetry: refresh));
              }
              return SliverMainAxisGroup(
                slivers: [
                  box(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: data.refreshing ? null : refresh,
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
                          SizedBox(height: AppSize.vertical(16)),
                        ],
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    box(
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
                    )
                  else
                    SliverList.builder(
                      itemCount: items.length,
                      findChildIndexCallback: (key) {
                        final index = items.indexWhere(
                          (item) => ValueKey(item.id) == key,
                        );
                        return index < 0 ? null : index;
                      },
                      itemBuilder: (context, index) => Padding(
                        key: ValueKey(items[index].id),
                        padding: EdgeInsets.only(bottom: AppSize.vertical(16)),
                        child: BookingCard(booking: items[index]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
