import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.role,
  });
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      email: _requiredString(json, 'email'),
      role: json['role'] == 'ADMIN' ? UserRole.admin : UserRole.customer,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw InvalidAuthResponseException(
        'The user response has an invalid $key.',
      );
    }
    return value;
  }
}
