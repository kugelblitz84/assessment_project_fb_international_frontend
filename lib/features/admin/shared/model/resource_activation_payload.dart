class ResourceActivationPayload {
  const ResourceActivationPayload(this.isActive);
  final bool isActive;
  Map<String, dynamic> toJson() => {'isActive': isActive};
}
