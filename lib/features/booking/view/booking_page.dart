import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/navigation/presentation/page_scaffold.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/responsive/adaptive_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
import 'widgets/booking_date_selector.dart';
import 'widgets/booking_action_button.dart';
import 'widgets/booking_review_section.dart';
import 'widgets/booking_step_indicator.dart';

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
    if (lifecycle != AppLifecycleState.resumed ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    ref
        .read(bookingControllerProvider(widget.serviceId).notifier)
        .refreshAvailability();
  }

  Future<void> _pickDate(BookingState draft) async {
    final controller = ref.read(
      bookingControllerProvider(widget.serviceId).notifier,
    );
    final today = controller.firstBookableDate;
    final date = await showDatePicker(
      context: context,
      initialDate: draft.date.isBefore(today) ? today : draft.date,
      firstDate: today,
      lastDate: controller.lastBookableDate,
      helpText: 'Choose appointment date',
    );
    if (date != null && mounted) {
      ref
          .read(bookingControllerProvider(widget.serviceId).notifier)
          .selectDate(date);
    }
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
    return AppPageScaffold(
      title: 'Book appointment',
      bottomBar: !desktop && draft != null && service != null
          ? PriceActionBar(
              price: Formatters.price(service.price, service.currency),
              action: BookingActionButton(serviceId: widget.serviceId),
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
                      SizedBox(height: AppSize.vertical(8)),
                      Text(
                        service.name,
                        style: const TextStyle(color: AppColors.secondary),
                      ),
                      SizedBox(height: AppSize.vertical(24)),
                      Semantics(
                        label:
                            '${draft.step.index + 1} of 2: ${draft.step == BookingStep.schedule ? 'Schedule' : 'Review and book'}',
                        child: ExcludeSemantics(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              BookingStepIndicator(
                                number: '1',
                                label: 'Schedule',
                                active: draft.step == BookingStep.schedule,
                              ),
                              Icon(
                                Icons.arrow_forward,
                                size: AppSize.icon(18),
                                color: AppColors.secondary,
                              ),
                              BookingStepIndicator(
                                number: '2',
                                label: 'Review & book',
                                active: draft.step == BookingStep.review,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.vertical(24)),
                      if (draft.errorCode != null) ...[
                        InlineNotice(
                          message: draft.uncertain
                              ? 'We could not confirm whether your request was received. Check My Bookings before making another request.'
                              : ApiErrorHandler.messageFor(draft.errorCode),
                          error: true,
                        ),
                        SizedBox(height: AppSize.vertical(20)),
                      ],
                      AdaptiveColumns(
                        main: draft.step == BookingStep.schedule
                            ? BookingDateSelector(
                                draft: draft,
                                onPickDate: () => _pickDate(draft),
                                onRefresh: ref
                                    .read(
                                      bookingControllerProvider(
                                        widget.serviceId,
                                      ).notifier,
                                    )
                                    .refreshAvailability,
                                onSlotSelected: ref
                                    .read(
                                      bookingControllerProvider(
                                        widget.serviceId,
                                      ).notifier,
                                    )
                                    .selectSlot,
                              )
                            : BookingReviewSection(
                                draft: draft,
                                onRefresh: ref
                                    .read(
                                      bookingControllerProvider(
                                        widget.serviceId,
                                      ).notifier,
                                    )
                                    .refreshAvailability,
                                onEdit: ref
                                    .read(
                                      bookingControllerProvider(
                                        widget.serviceId,
                                      ).notifier,
                                    )
                                    .edit,
                              ),
                        aside: ServicePriceSummary(
                          service: service,
                          action: desktop
                              ? BookingActionButton(serviceId: widget.serviceId)
                              : null,
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
                                style: TextStyle(
                                  fontSize: AppSize.font(12),
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
}
