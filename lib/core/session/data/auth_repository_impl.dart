import 'package:dio/dio.dart';

import '../../network/api_endpoints.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/session_exception.dart';
import '../domain/user_entity.dart';
import 'user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

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
      if (error.response?.statusCode == 401) {
        if (restoringSession) throw const InvalidSessionException();
        throw const InvalidCredentialsException();
      }
      if (error.error is FormatException) {
        throw const InvalidAuthResponseException();
      }
      final message = switch (error.response?.statusCode) {
        400 || 422 => 'Please check the submitted details.',
        403 => 'This request is not allowed.',
        409 => 'An account with this email already exists.',
        final int code when code >= 500 =>
          'The server is unavailable. Please try again.',
        _ => 'Unable to connect to AutoCare. Please try again.',
      };
      // Do not expose raw Dio errors: they can contain request credentials.
      throw AuthRequestException(message);
    } on FormatException {
      throw const InvalidAuthResponseException();
    }
  }
}
