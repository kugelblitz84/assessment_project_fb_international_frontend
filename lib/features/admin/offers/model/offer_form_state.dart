class OfferFormState {
  const OfferFormState({
    required this.serviceId,
    this.type = 'PERCENTAGE',
    this.active = true,
    this.error,
  });
  final String serviceId, type;
  final bool active;
  final String? error;
  OfferFormState copyWith({
    String? serviceId,
    String? type,
    bool? active,
    String? error,
  }) => OfferFormState(
    serviceId: serviceId ?? this.serviceId,
    type: type ?? this.type,
    active: active ?? this.active,
    error: error,
  );
}
