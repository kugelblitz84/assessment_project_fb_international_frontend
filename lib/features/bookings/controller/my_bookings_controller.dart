import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/session/application/session_controller.dart';

enum BookingsTab { upcoming, previous }

final myBookingsTabProvider =
    NotifierProvider<MyBookingsController, BookingsTab>(
      MyBookingsController.new,
    );

class MyBookingsController extends Notifier<BookingsTab> {
  @override
  BookingsTab build() {
    ref.watch(sessionProvider);
    return BookingsTab.upcoming;
  }

  void select(BookingsTab tab) => state = tab;
}
