class UpdateProfilePayload {
  const UpdateProfilePayload({required this.name, required this.email});
  final String name;
  final String email;
  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}
