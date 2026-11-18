import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/features/booking/model/booking_state.dart';
import 'package:assessment_project_fb_international_frontend/features/booking/view/widgets/booking_date_selector.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';

void main() {
  final date = DateTime.utc(2030, 1, 1);
  TimeSlotModel slot(String id, bool available) => TimeSlotModel(
    id: id,
    startsAt: date.add(const Duration(hours: 9)),
    endsAt: date.add(const Duration(hours: 10)),
    workshopTime: date.add(const Duration(hours: 15)),
    timeZone: 'Asia/Dhaka',
    available: available,
  );

  Future<void> showPicker(
    WidgetTester tester,
    List<TimeSlotModel> slots, {
    String? selected,
    ValueChanged<String>? onSelected,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, child) => MaterialApp(home: Scaffold(body: child)),
        child: SingleChildScrollView(
          child: BookingDateSelector(
            draft: BookingState(
              date: date,
              slotId: selected,
              availability: AvailabilityModel(
                date: date,
                timeZone: 'Asia/Dhaka',
                slots: slots,
              ),
            ),
            onPickDate: () {},
            onRefresh: () {},
            onSlotSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('one time button selects the available bay internally', (
    tester,
  ) async {
    String? chosen;
    await showPicker(tester, [
      slot('occupied', false),
      slot('free', true),
    ], onSelected: (id) => chosen = id);
    expect(find.byType(ChoiceChip), findsOneWidget);
    expect(find.text('3:00 PM'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    await tester.tap(find.byType(ChoiceChip));
    expect(chosen, 'free');
  });

  testWidgets('time is disabled when all bays are unavailable', (tester) async {
    await showPicker(tester, [slot('one', false), slot('two', false)]);
    expect(find.byType(ChoiceChip), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip)).onSelected,
      isNull,
    );
    expect(find.text('Unavailable'), findsOneWidget);
  });

  testWidgets('selected bay stays selected with multiple available bays', (
    tester,
  ) async {
    await showPicker(tester, [
      slot('one', true),
      slot('two', true),
    ], selected: 'two');
    expect(find.byType(ChoiceChip), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
  });
}
