import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/app/shell/page_scaffold.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_resume_listener.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/page_container.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/price_action_bar.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/responsive/adaptive_layout.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/view/widgets/appointment_info.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/controller/booking_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/widgets/booking_action_button.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/widgets/booking_date_selector.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/widgets/booking_review_section.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/widgets/booking_step_indicator.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/service_details_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/widgets/service_price_summary.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class BookingPage extends ConsumerWidget {
  const BookingPage({super.key, required this.serviceId});
  final String serviceId;

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(bookingControllerProvider(serviceId).notifier);
    final selection = controller.prepareDateSelection();
    if (selection == null) return;
    final date = await showDatePicker(
      context: context,
      initialDate: selection.initialDate,
      firstDate: selection.firstDate,
      lastDate: selection.lastDate,
      helpText: 'Choose appointment date',
    );
    if (date == null ||
        !context.mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    await controller.selectDate(date, selection: selection);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailsProvider(serviceId));
    final service = serviceAsync.asData?.value;
    final catalogError = ref.watch(
      catalogControllerProvider.select(
        (catalog) => catalog.asData?.value.errorCode,
      ),
    );
    final provider = bookingControllerProvider(serviceId);
    final draftAsync = ref.watch(provider);
    final controller = ref.watch(provider.notifier);
    final draft = draftAsync.asData?.value;
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    ref.listen(provider, (previous, next) {
      final created = next.asData?.value.created;
      if (created != null &&
          previous?.asData?.value.created?.id != created.id) {
        context.goNamed(
          AppRoutes.bookingConfirmation,
          pathParameters: {'bookingId': created.id},
        );
      }
    });
    return AppResumeListener(
      onResume: controller.refreshAvailability,
      child: AppPageScaffold(
        title: 'Book appointment',
        bottomBar: !desktop && draft != null && service != null
            ? PriceActionBar(
                price: Formatters.price(service.price, service.currency),
                action: BookingActionButton(serviceId: serviceId),
              )
            : null,
        body: SingleChildScrollView(
          child: PageContainer(
            child: serviceAsync.isLoading
                ? const LoadingState(label: 'Loading service…')
                : service == null
                ? ErrorState(
                    code: catalogError ?? 'NOT_FOUND',
                    onRetry: () => ref.invalidate(catalogControllerProvider),
                  )
                : draftAsync.when(
                    loading: () => const LoadingState(
                      label: 'Checking appointment times…',
                    ),
                    error: (error, _) => ErrorState(
                      code: ApiErrorHandler.codeFor(error),
                      onRetry: () => ref.invalidate(provider),
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
                                : AppErrorMessages.messageFor(draft.errorCode),
                            error: true,
                          ),
                          SizedBox(height: AppSize.vertical(20)),
                        ],
                        AdaptiveColumns(
                          main: draft.step == BookingStep.schedule
                              ? BookingDateSelector(
                                  draft: draft,
                                  onPickDate: () => _pickDate(context, ref),
                                  onRefresh: controller.refreshAvailability,
                                  onSlotSelected: controller.selectSlot,
                                )
                              : BookingReviewSection(
                                  draft: draft,
                                  onRefresh: controller.refreshAvailability,
                                  onEdit: controller.edit,
                                ),
                          aside: ServicePriceSummary(
                            service: service,
                            action: desktop
                                ? BookingActionButton(serviceId: serviceId)
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
      ),
    );
  }
}
