class PaymentFilterState {
  const PaymentFilterState({this.status = ''});
  final String status;
  String? get query => status.isEmpty ? null : status;
}
