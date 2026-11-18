import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/input_validation_exception.dart';

/// The result of a feature service operation, including no-content successes.
class ApiResponse<T> {
  const ApiResponse.success(this.data)
    : success = true,
      errorCode = null,
      statusCode = null;

  const ApiResponse.failure(String code, {this.statusCode})
    : success = false,
      data = null,
      errorCode = code;

  final T? data;
  final bool success;
  final String? errorCode;
  final int? statusCode;

  bool get isUnauthorized =>
      statusCode == 401 ||
      errorCode == 'UNAUTHORIZED' ||
      errorCode == 'SESSION_EXPIRED';
}

/// Wraps feature requests without changing authentication or retry behavior.
abstract final class ApiErrorHandler {
  static Future<ApiResponse<T>> run<T>(Future<T> Function() action) async {
    try {
      return ApiResponse<T>.success(await action());
    } catch (error, stack) {
      final code = codeFor(error);
      // Never log exception text: Dio errors and programmer errors may hold input.
      if (code == 'UNEXPECTED_ERROR') {
        developer.log(
          'Unexpected operation failure: ${error.runtimeType}',
          name: 'autocare.api',
          stackTrace: stack,
        );
      }
      return ApiResponse<T>.failure(
        code,
        statusCode: error is DioException ? error.response?.statusCode : null,
      );
    }
  }

  static String codeFor(Object error) => switch (error) {
    ApiFailure(:final code) => code,
    InputValidationException() => 'VALIDATION_ERROR',
    DioException() => _codeForDio(error),
    SessionException() => _codeForSession(error),
    FormatException() => 'INVALID_RESPONSE',
    _ => 'UNEXPECTED_ERROR',
  };

  static String _codeForDio(DioException error) {
    // Interceptor rejections and JSON decoding failures can be wrapped by Dio.
    final cause = error.error;
    if (cause is ApiFailure) return cause.code;
    if (cause is SessionException) return _codeForSession(cause);
    if (cause is FormatException) {
      return 'INVALID_RESPONSE';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'CONNECTION_TIMEOUT';
      case DioExceptionType.sendTimeout:
        return 'SEND_TIMEOUT';
      case DioExceptionType.receiveTimeout:
        return 'RECEIVE_TIMEOUT';
      case DioExceptionType.cancel:
        return 'CANCELLED';
      case DioExceptionType.connectionError:
        return 'NETWORK_ERROR';
      default:
        break;
    }

    final status = error.response?.statusCode;
    final body = error.response?.data;
    final domainCode = body is Map ? body['code'] : null;
    const domainCodes = {
      'PAYMENT_NOT_ELIGIBLE',
      'APPOINTMENT_ALREADY_PAID',
      'PAYMENT_UNRESOLVED',
      'PAYMENT_REVIEW_REQUIRED',
      'PAYMENT_CANCELLATION_BLOCKED',
      'PAYMENT_CONTACT_UNSUPPORTED',
      'PAYMENT_RATE_LIMITED',
      'PAYMENT_RECONCILE_THROTTLED',
      'PAYMENTS_DISABLED',
      'PAYMENT_INITIATION_UNCERTAIN',
      'PAYMENT_GATEWAY_UNAVAILABLE',
      'PAYMENT_VERIFICATION_UNAVAILABLE',
      'ASSISTANT_DISABLED',
      'ASSISTANT_CONFIGURATION_ERROR',
      'ASSISTANT_CONTEXT_TOO_LARGE',
      'ASSISTANT_RATE_LIMITED',
      'ASSISTANT_DAILY_LIMIT',
      'ASSISTANT_BUSY',
      'ASSISTANT_QUOTA_EXHAUSTED',
      'ASSISTANT_TIMEOUT',
      'ASSISTANT_INVALID_RESPONSE',
      'ASSISTANT_PROVIDER_ERROR',
      'ASSISTANT_EMPTY_RESPONSE',
      'ASSISTANT_BLOCKED',
      'ASSISTANT_SENSITIVE_INPUT',
    };
    if (domainCode is String && domainCodes.contains(domainCode)) {
      return domainCode;
    }
    // Domain codes require a verified backend contract. A generic 409 does not
    // imply that an appointment slot is unavailable.
    return switch (status) {
      400 || 422 => 'VALIDATION_ERROR',
      401 => 'UNAUTHORIZED',
      403 => 'FORBIDDEN',
      404 => 'NOT_FOUND',
      409 => 'CONFLICT',
      413 =>
        error.requestOptions.path == '/admin/media/images'
            ? 'IMAGE_TOO_LARGE'
            : 'PAYLOAD_TOO_LARGE',
      429 => 'RATE_LIMITED',
      503 when error.requestOptions.path == '/admin/media/images' =>
        'IMAGE_UPLOAD_UNAVAILABLE',
      503 => 'BACKEND_UNAVAILABLE',
      _ when status != null && status >= 500 => 'SERVER_ERROR',
      _ => 'UNEXPECTED_ERROR',
    };
  }

  static String _codeForSession(SessionException error) => switch (error) {
    InvalidSessionException() => 'SESSION_EXPIRED',
    InvalidCredentialsException() => 'INVALID_CREDENTIALS',
    SecureStorageException() => 'SECURE_STORAGE_ERROR',
    InvalidAuthResponseException() => 'INVALID_RESPONSE',
    AuthRequestException(:final code) => code,
  };
}
