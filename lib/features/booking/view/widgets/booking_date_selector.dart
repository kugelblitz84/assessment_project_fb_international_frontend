import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';

class BookingDateSelector extends StatelessWidget {
  const BookingDateSelector({
    super.key,
    required this.draft,
    required this.onPickDate,
    required this.onRefresh,
    required this.onSlotSelected,
  });
  final BookingState draft;
  final VoidCallback onPickDate;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSlotSelected;
  @override
  Widget build(BuildContext context) {
    // Bay-specific IDs stay internal; customers choose a time window once.
    final windows = <(DateTime, DateTime?), TimeSlotModel>{};
    for (final slot in draft.availability?.slots ?? const <TimeSlotModel>[]) {
      final key = (slot.startsAt, slot.endsAt);
      final existing = windows[key];
      if (existing == null ||
          (slot.available &&
              (!existing.available || slot.id == draft.slotId))) {
        windows[key] = slot;
      }
    }
    final slots = windows.values.toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return AppSurface(
      child: Padding(
        padding: AppSize.inset(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your date',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: AppSize.vertical(8)),
            const Text(
              'Find a time that fits your day.',
              style: TextStyle(color: AppColors.secondary),
            ),
            SizedBox(height: AppSize.vertical(20)),
            OutlinedButton.icon(
              onPressed: draft.submitting || draft.uncertain
                  ? null
                  : onPickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(Formatters.date(draft.date)),
            ),
            SizedBox(height: AppSize.vertical(28)),
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
                      : () => onRefresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (draft.availability != null)
              Text(
                draft.availability!.timeZone,
                style: TextStyle(
                  fontSize: AppSize.font(12),
                  color: AppColors.secondary,
                ),
              ),
            SizedBox(height: AppSize.vertical(16)),
            if (draft.loadingSlots)
              const LoadingState(label: 'Checking availability…')
            else if (draft.availabilityError != null)
              ErrorState(
                code: draft.availabilityError,
                onRetry: () => onRefresh(),
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
                if (slots.any(
                  (s) =>
                      s.workshopTime.hour >= period.start &&
                      s.workshopTime.hour < period.end,
                )) ...[
                  Text(
                    period.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSize.vertical(8)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in slots.where(
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
                                ? (_) => onSlotSelected(slot.id)
                                : null,
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(Formatters.time(slot.workshopTime)),
                                if (!slot.available)
                                  Text(
                                    'Unavailable',
                                    style: TextStyle(
                                      fontSize: AppSize.font(11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSize.vertical(20)),
                ],
              Text(
                'Availability is checked again when you book.',
                style: TextStyle(
                  fontSize: AppSize.font(12),
                  color: AppColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
