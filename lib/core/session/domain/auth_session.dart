import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final UserEntity user;
}
