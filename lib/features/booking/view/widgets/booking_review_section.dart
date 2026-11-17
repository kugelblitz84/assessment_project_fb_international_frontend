import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../shared/view/appointment_info.dart';
import '../../model/booking_state.dart';

class BookingReviewSection extends StatelessWidget {
  const BookingReviewSection({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.onRefresh,
  });
  final BookingState draft;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppSize.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('One last look', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppSize.vertical(8)),
          const Text(
            'Check your appointment details before sending your request.',
            style: TextStyle(color: AppColors.secondary),
          ),
          SizedBox(height: AppSize.vertical(20)),
          if (draft.loadingSlots) ...[
            const LinearProgressIndicator(),
            SizedBox(height: AppSize.vertical(16)),
          ],
          if (draft.availabilityError != null) ...[
            InlineNotice(
              message: ApiErrorHandler.messageFor(draft.availabilityError),
              error: true,
            ),
            TextButton.icon(
              onPressed: draft.loadingSlots ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh available times'),
            ),
            SizedBox(height: AppSize.vertical(16)),
          ],
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
          SizedBox(height: AppSize.vertical(12)),
          const InlineNotice(
            message:
                'You’ll receive a booking request acknowledgement. Your appointment status will appear in My Bookings.',
          ),
          SizedBox(height: AppSize.vertical(16)),
          OutlinedButton.icon(
            onPressed: draft.submitting || draft.uncertain ? null : onEdit,
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Change date or time'),
          ),
        ],
      ),
    ),
  );
}
