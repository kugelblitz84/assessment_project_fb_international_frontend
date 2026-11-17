import 'package:dio/dio.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/token_refresh_coordinator.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/user_model.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_repository.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/api_error_messages.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._dio, {
    required TokenRefreshCoordinator coordinator,
    required Dio transport,
  }) : _coordinator = coordinator,
       _transport = transport;
  final TokenRefreshCoordinator _coordinator;
  final Dio _transport;
  @override
  Future<String> refresh() => _coordinator.refresh();
  @override
  Future<void> logout() => _request(() async {
    await _transport.post<Object?>(ApiEndpoints.logout);
  }, restoringSession: true);

  final Dio _dio;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) =>
      _authenticate(ApiEndpoints.login, {'email': email, 'password': password});

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate(ApiEndpoints.register, {
    'name': name,
    'email': email,
    'password': password,
  });

  Future<AuthSession> _authenticate(
    String endpoint,
    Map<String, String> fields,
  ) => _request(() async {
    final response = await _dio.post<Object?>(endpoint, data: fields);
    final json = _object(response.data);
    final token = json['accessToken'];
    if (token is! String || token.trim().isEmpty) {
      throw const InvalidAuthResponseException();
    }
    return AuthSession(
      accessToken: token,
      user: UserModel.fromJson(_object(json['user'])),
    );
  });

  @override
  Future<UserEntity> getCurrentUser({required String token}) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          ApiEndpoints.currentUser,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return UserModel.fromJson(_object(_object(response.data)['user']));
      }, restoringSession: true);

  static Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const InvalidAuthResponseException();
    }
    return value;
  }

  Future<T> _request<T>(
    Future<T> Function() request, {
    bool restoringSession = false,
  }) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.error is SessionException) throw error.error!;
      if (error.response?.statusCode == 401) {
        if (restoringSession) throw const InvalidSessionException();
        throw const InvalidCredentialsException();
      }
      if (error.error is FormatException) {
        throw const InvalidAuthResponseException();
      }
      final code = ApiErrorHandler.codeFor(error);
      throw AuthRequestException(ApiErrorMessages.messageFor(code), code: code);
    } on FormatException {
      throw const InvalidAuthResponseException();
    }
  }
}
