import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';

class AssistantState {
  const AssistantState({
    this.messages = const [],
    this.sending = false,
    this.errorCode,
    this.failedMessageId,
  });
  final List<AssistantMessageModel> messages;
  final bool sending;
  final String? errorCode;
  final String? failedMessageId;
  AssistantState copyWith({
    List<AssistantMessageModel>? messages,
    bool? sending,
    String? errorCode,
    String? failedMessageId,
    bool clearError = false,
  }) => AssistantState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    failedMessageId: clearError
        ? null
        : failedMessageId ?? this.failedMessageId,
  );
}
