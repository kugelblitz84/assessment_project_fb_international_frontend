class CreateBookingPayload {
  const CreateBookingPayload({required this.serviceId, required this.slotId});
  final String serviceId;
  final String slotId;
  Map<String, dynamic> toJson() => {'serviceId': serviceId, 'slotId': slotId};
}
