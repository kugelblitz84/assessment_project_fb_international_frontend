import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/responsive/adaptive_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/price_action_bar.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/service_details_controller.dart';
import '../../shared/controller/catalog_controller.dart';
import '../../shared/view/appointment_info.dart';
import '../../shared/view/service_price_summary.dart';
import '../controller/booking_controller.dart';
import '../model/booking_state.dart';
import '../service/booking_service.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed) return;
    final draft = ref
        .read(bookingControllerProvider(widget.serviceId))
        .asData
        ?.value;
    if (draft != null && !draft.submitting && !draft.uncertain) {
      ref
          .read(bookingControllerProvider(widget.serviceId).notifier)
          .selectDate(draft.date);
    }
  }

  Future<void> _pickDate(BookingState draft) async {
    final today = ref.read(bookingServiceProvider).today;
    final date = await showDatePicker(
      context: context,
      initialDate: draft.date.isBefore(today) ? today : draft.date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Choose appointment date',
    );
    if (date != null && mounted) {
      ref
          .read(bookingControllerProvider(widget.serviceId).notifier)
          .selectDate(date);
    }
  }

  Widget _action(BookingState draft) {
    if (draft.uncertain) {
      return AppButton(
        label: 'Check my bookings',
        onPressed: () => context.goNamed(AppRoutes.myBookings),
      );
    }
    final controller = ref.read(
      bookingControllerProvider(widget.serviceId).notifier,
    );
    return AppButton(
      label: draft.submitting
          ? 'Submitting booking…'
          : draft.step == 0
          ? 'Continue to review'
          : 'Confirm booking',
      loading: draft.submitting,
      onPressed: draft.canContinue
          ? (draft.step == 0 ? controller.review : controller.submit)
          : null,
      icon: draft.step == 0 ? Icons.arrow_forward : Icons.check,
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailsProvider(widget.serviceId));
    final service = serviceAsync.asData?.value;
    final draftAsync = ref.watch(bookingControllerProvider(widget.serviceId));
    final draft = draftAsync.asData?.value;
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    ref.listen(bookingControllerProvider(widget.serviceId), (previous, next) {
      final created = next.asData?.value.created;
      if (created != null &&
          previous?.asData?.value.created?.id != created.id) {
        context.goNamed(
          AppRoutes.bookingConfirmation,
          pathParameters: {'bookingId': created.id},
        );
      }
    });
    return AdaptiveAppShell(
      title: 'Book appointment',
      bottomBar: !desktop && draft != null && service != null
          ? PriceActionBar(
              price: Formatters.price(service.price, service.currency),
              action: _action(draft),
            )
          : null,
      body: SingleChildScrollView(
        child: PageContainer(
          child: serviceAsync.isLoading
              ? const LoadingState(label: 'Loading service…')
              : service == null
              ? ErrorState(
                  code:
                      ref
                          .watch(catalogControllerProvider)
                          .asData
                          ?.value
                          .errorCode ??
                      'NOT_FOUND',
                  onRetry: () => ref.invalidate(catalogControllerProvider),
                )
              : draftAsync.when(
                  loading: () =>
                      const LoadingState(label: 'Checking appointment times…'),
                  error: (_, _) => ErrorState(
                    onRetry: () => ref.invalidate(
                      bookingControllerProvider(widget.serviceId),
                    ),
                  ),
                  data: (draft) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Book appointment',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.name,
                        style: const TextStyle(color: AppColors.secondary),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        label:
                            '${draft.step + 1} of 2: ${draft.step == 0 ? 'Schedule' : 'Review and book'}',
                        child: ExcludeSemantics(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _Step(
                                number: '1',
                                label: 'Schedule',
                                active: draft.step == 0,
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              _Step(
                                number: '2',
                                label: 'Review & book',
                                active: draft.step == 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (draft.errorCode != null) ...[
                        InlineNotice(
                          message: draft.uncertain
                              ? 'We could not confirm whether your request was received. Check My Bookings before making another request.'
                              : ApiErrorHandler.messageFor(draft.errorCode),
                          error: true,
                        ),
                        const SizedBox(height: 20),
                      ],
                      AdaptiveColumns(
                        main: draft.step == 0
                            ? _schedule(draft)
                            : _review(draft),
                        aside: ServicePriceSummary(
                          service: service,
                          action: desktop ? _action(draft) : null,
                          children: [
                            DetailLine(
                              label: 'Date',
                              value: Formatters.date(draft.date),
                            ),
                            DetailLine(
                              label: 'Time',
                              value: draft.selectedSlot == null
                                  ? 'Choose an available time'
                                  : Formatters.time(
                                      draft.selectedSlot!.workshopTime,
                                    ),
                            ),
                            if (draft.availability != null)
                              Text(
                                draft.availability!.timeZone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _schedule(BookingState draft) {
    final controller = ref.read(
      bookingControllerProvider(widget.serviceId).notifier,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your date',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Find a time that fits your day.',
              style: TextStyle(color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: draft.submitting || draft.uncertain
                  ? null
                  : () => _pickDate(draft),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(Formatters.date(draft.date)),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Available times',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh available times',
                  onPressed:
                      draft.loadingSlots || draft.submitting || draft.uncertain
                      ? null
                      : () => controller.selectDate(draft.date),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (draft.availability != null)
              Text(
                draft.availability!.timeZone,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
            const SizedBox(height: 16),
            if (draft.loadingSlots)
              const LoadingState(label: 'Checking availability…')
            else if (draft.availabilityError != null)
              ErrorState(
                code: draft.availabilityError,
                onRetry: () => controller.selectDate(draft.date),
              )
            else if (draft.availability?.slots.isEmpty != false)
              const StateMessage(
                title: 'No times available',
                message: 'Choose another date to find an appointment.',
                icon: Icons.event_busy,
              )
            else ...[
              for (final period in [
                (label: 'Morning', start: 0, end: 12),
                (label: 'Afternoon', start: 12, end: 17),
                (label: 'Evening', start: 17, end: 24),
              ])
                if (draft.availability!.slots.any(
                  (s) =>
                      s.workshopTime.hour >= period.start &&
                      s.workshopTime.hour < period.end,
                )) ...[
                  Text(
                    period.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in draft.availability!.slots.where(
                        (s) =>
                            s.workshopTime.hour >= period.start &&
                            s.workshopTime.hour < period.end,
                      ))
                        Semantics(
                          label:
                              '${Formatters.time(slot.workshopTime)}, ${slot.available ? 'available' : 'unavailable'}',
                          selected: draft.slotId == slot.id,
                          enabled: slot.available,
                          child: ChoiceChip(
                            selected: draft.slotId == slot.id,
                            onSelected: slot.available && !draft.uncertain
                                ? (_) => controller.selectSlot(slot.id)
                                : null,
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(Formatters.time(slot.workshopTime)),
                                if (!slot.available)
                                  const Text(
                                    'Unavailable',
                                    style: TextStyle(fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              const Text(
                'Availability is checked again when you book.',
                style: TextStyle(fontSize: 12, color: AppColors.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _review(BookingState draft) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('One last look', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Check your appointment details before sending your request.',
            style: TextStyle(color: AppColors.secondary),
          ),
          const SizedBox(height: 20),
          DetailLine(
            label: 'Appointment date',
            value: Formatters.date(draft.date),
            icon: Icons.calendar_month_outlined,
          ),
          if (draft.selectedSlot != null)
            DetailLine(
              label: 'Appointment time',
              value:
                  '${Formatters.time(draft.selectedSlot!.workshopTime)}\n${draft.selectedSlot!.timeZone}',
              icon: Icons.schedule_outlined,
            ),
          const SizedBox(height: 12),
          const InlineNotice(
            message:
                'You’ll receive a booking request acknowledgement. Your appointment status will appear in My Bookings.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: draft.submitting || draft.uncertain
                ? null
                : ref
                      .read(
                        bookingControllerProvider(widget.serviceId).notifier,
                      )
                      .edit,
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Change date or time'),
          ),
        ],
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.active,
  });
  final String number;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: active ? AppColors.primary : AppColors.border,
        foregroundColor: active ? Colors.white : AppColors.secondary,
        child: Text(number, style: const TextStyle(fontSize: 13)),
      ),
      Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : AppColors.secondary,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );
}
