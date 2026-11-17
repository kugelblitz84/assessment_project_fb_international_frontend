import 'package:assessment_project_fb_international_frontend/core/utils/api_error_messages.dart';

/// The application's sole business-message lookup. No backend text is rendered.
abstract final class AppErrorMessages {
  static String messageFor(String? code) => switch (code) {
    'PAYMENT_NOT_ELIGIBLE' =>
      'Online payment is not available for this appointment. Refresh its details.',
    'APPOINTMENT_ALREADY_PAID' =>
      'This appointment already has an applied payment. Do not pay again.',
    'PAYMENT_UNRESOLVED' =>
      'An existing payment is unresolved. Refresh its status before paying again.',
    'PAYMENT_REVIEW_REQUIRED' =>
      'This payment needs manual review. Contact workshop support and do not pay again.',
    'PAYMENT_CANCELLATION_BLOCKED' =>
      'Paid or unresolved payments block cancellation. Refresh payment status or contact support.',
    'PAYMENT_CONTACT_UNSUPPORTED' =>
      'Update your profile name/email to at most 50 characters or pay at the workshop.',
    'PAYMENT_RATE_LIMITED' =>
      'The payment request limit was reached. Wait before trying again.',
    'PAYMENT_RECONCILE_THROTTLED' =>
      'Wait at least five seconds before refreshing payment status.',
    'PAYMENTS_DISABLED' =>
      'Online payment is unavailable. Your booking remains valid; pay at the workshop.',
    'PAYMENT_INITIATION_UNCERTAIN' =>
      'Checkout may have started. Refresh the existing payment before another attempt.',
    'PAYMENT_GATEWAY_UNAVAILABLE' =>
      'The gateway is unavailable. Refresh payment history before another attempt.',
    'PAYMENT_VERIFICATION_UNAVAILABLE' =>
      'Payment could not be verified. Refresh later; do not pay again yet.',
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
    'IMAGE_TOO_LARGE' => 'Choose an image no larger than 2 MB.',
    'IMAGE_UPLOAD_UNAVAILABLE' =>
      'Image upload is unavailable. Your previous image is preserved. Try again later or contact the workshop administrator.',
    _ => ApiErrorMessages.messageFor(code),
  };
}
