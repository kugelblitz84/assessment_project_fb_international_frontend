enum PaymentSummary {
  unpaid,
  pending,
  paid,
  reviewRequired;

  static PaymentSummary parse(String value) => switch (value) {
    'unpaid' => unpaid,
    'pending' => pending,
    'paid' => paid,
    'review_required' => reviewRequired,
    _ => throw const FormatException('Invalid payment summary.'),
  };
  String get label => switch (this) {
    unpaid => 'Unpaid',
    pending => 'Processing',
    paid => 'Paid',
    reviewRequired => 'Manual review required',
  };
}

String? paymentMethodFromJson(Object? value) {
  if (value == null || value == 'sslcommerz') return value as String?;
  throw const FormatException('Unsupported payment method.');
}
