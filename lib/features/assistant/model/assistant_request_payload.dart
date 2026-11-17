import 'assistant_message_model.dart';

class AssistantRequestPayload {
  const AssistantRequestPayload({required this.messages});
  final List<AssistantMessageModel> messages;
  Map<String, dynamic> toJson() => {
    'messages': [
      for (final message in messages)
        {'role': message.role.name, 'content': message.text},
    ],
  };
}
