import 'assistant_message_model.dart';

class AssistantRequestPayload {
  const AssistantRequestPayload({required this.messages});
  final List<AssistantMessageModel> messages;
  Map<String, dynamic> toJson() {
    final recent = <Map<String, String>>[];
    var characters = 0;
    for (final message in messages.reversed.take(12)) {
      final content = message.text.length > 2000
          ? message.text.substring(0, 2000)
          : message.text;
      if (characters + content.length > 12000) break;
      recent.insert(0, {'role': message.role.name, 'content': content});
      characters += content.length;
    }
    return {'messages': recent};
  }
}
