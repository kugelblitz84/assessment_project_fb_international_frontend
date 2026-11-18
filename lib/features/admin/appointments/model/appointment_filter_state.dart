class AppointmentFilterState {
  const AppointmentFilterState({this.status = '', this.date});
  final String status;
  final DateTime? date;
  ({String? status, String? date}) get query => (
    status: status.isEmpty ? null : status,
    date: date?.toIso8601String().substring(0, 10),
  );
}
