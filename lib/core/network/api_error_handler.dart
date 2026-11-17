import 'package:dio/dio.dart';

import '../session/domain/session_exception.dart';
import 'backend_contract_exception.dart';

/// The result of a feature service operation, including no-content successes.
class ApiResponse<T> {
  const ApiResponse.success(this.data) : success = true, errorCode = null;

  const ApiResponse.failure(String code)
    : success = false,
      data = null,
      errorCode = code;

  final T? data;
  final bool success;
  final String? errorCode;
}

/// Wraps feature requests without changing authentication or retry behavior.
abstract final class ApiErrorHandler {
  static Future<ApiResponse<T>> run<T>(Future<T> Function() action) async {
    try {
      return ApiResponse<T>.success(await action());
    } on BackendContractException {
      return ApiResponse<T>.failure('NOT_CONFIGURED');
    } on DioException catch (error) {
      return ApiResponse<T>.failure(_codeForDio(error));
    } on SessionException catch (error) {
      return ApiResponse<T>.failure(_codeForSession(error));
    } on FormatException {
      return ApiResponse<T>.failure('INVALID_RESPONSE');
    } on TypeError {
      return ApiResponse<T>.failure('INVALID_RESPONSE');
    } catch (_) {
      return ApiResponse<T>.failure('UNEXPECTED_ERROR');
    }
  }

  static String _codeForDio(DioException error) {
    // Interceptor rejections and JSON decoding failures can be wrapped by Dio.
    final cause = error.error;
    if (cause is SessionException) return _codeForSession(cause);
    if (cause is FormatException || cause is TypeError) {
      return 'INVALID_RESPONSE';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT';
      case DioExceptionType.connectionError:
        return 'NETWORK_ERROR';
      default:
        break;
    }

    final status = error.response?.statusCode;
    final body = error.response?.data;
    final assistantCode = body is Map ? body['code'] : null;
    const assistantCodes = {
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
    if (assistantCode is String && assistantCodes.contains(assistantCode)) {
      return assistantCode;
    }
    // Domain codes require a verified backend contract. A generic 409 does not
    // imply that an appointment slot is unavailable.
    return switch (status) {
      400 || 422 => 'VALIDATION_ERROR',
      401 => 'UNAUTHORIZED',
      403 => 'FORBIDDEN',
      404 => 'NOT_FOUND',
      409 => 'CONFLICT',
      413 => 'IMAGE_TOO_LARGE',
      429 => 'RATE_LIMITED',
      _ when status != null && status >= 500 => 'SERVER_ERROR',
      _ => 'UNEXPECTED_ERROR',
    };
  }

  static String _codeForSession(SessionException error) => switch (error) {
    InvalidSessionException() ||
    InvalidCredentialsException() => 'UNAUTHORIZED',
    InvalidAuthResponseException() => 'INVALID_RESPONSE',
    AuthRequestException() => 'UNEXPECTED_ERROR',
  };

  /// Only locally defined copy is exposed to views, never server error details.
  static String messageFor(String? code) => switch (code) {
    'ASSISTANT_DISABLED' ||
    'ASSISTANT_CONFIGURATION_ERROR' ||
    'ASSISTANT_CONTEXT_TOO_LARGE' =>
      'The assistant is unavailable. You can still browse services.',
    'ASSISTANT_RATE_LIMITED' ||
    'ASSISTANT_DAILY_LIMIT' ||
    'ASSISTANT_BUSY' ||
    'ASSISTANT_QUOTA_EXHAUSTED' =>
      'The assistant request limit was reached. Try later or browse services.',
    'ASSISTANT_TIMEOUT' => 'The assistant took too long. Please try again.',
    'ASSISTANT_INVALID_RESPONSE' ||
    'ASSISTANT_PROVIDER_ERROR' ||
    'ASSISTANT_EMPTY_RESPONSE' =>
      'The assistant could not answer reliably. Try again or browse services.',
    'ASSISTANT_BLOCKED' =>
      'Please rephrase your question about AutoCare services.',
    'ASSISTANT_SENSITIVE_INPUT' =>
      'Remove personal details and credentials before sending.',
    'NOT_CONFIGURED' =>
      'This feature is not connected yet. Please try again later.',
    'NETWORK_ERROR' => 'Check your internet connection and try again.',
    'TIMEOUT' => 'The request took too long. Please try again.',
    'VALIDATION_ERROR' => 'Please check the information you entered.',
    'IMAGE_TOO_LARGE' => 'Choose an image no larger than 2 MB.',
    'UNAUTHORIZED' => 'Please sign in again to continue.',
    'FORBIDDEN' => 'You do not have permission to perform this action.',
    'NOT_FOUND' => 'The requested information could not be found.',
    'CONFLICT' =>
      'The request conflicts with current information. Refresh and try again.',
    'RATE_LIMITED' => 'Too many requests. Please try again shortly.',
    'SERVER_ERROR' =>
      'The service is temporarily unavailable. Try again later.',
    'INVALID_RESPONSE' =>
      'We could not load the information correctly. Try again.',
    _ => 'Something went wrong. Please try again.',
  };
}
