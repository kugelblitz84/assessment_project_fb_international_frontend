enum UserRole { customer, admin }

class UserEntity {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.customer,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  bool get isAdmin => role == UserRole.admin;
}
