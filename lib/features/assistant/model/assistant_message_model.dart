enum AssistantRole { user, assistant }

enum AssistantActionType { serviceDetails, browseServices }

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
String _identifier(Object? value) {
  if (value is! String || !_uuid.hasMatch(value)) {
    throw const FormatException('Invalid assistant identifier.');
  }
  return value;
}

void _keys(Map<String, dynamic> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown assistant fields.');
  }
}

class AssistantAction {
  const AssistantAction({required this.type, this.serviceId, this.categoryId});
  final AssistantActionType type;
  final String? serviceId;
  final String? categoryId;
  factory AssistantAction.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'serviceDetails':
        _keys(json, {'type', 'serviceId'});
        return AssistantAction(
          type: AssistantActionType.serviceDetails,
          serviceId: _identifier(json['serviceId']),
        );
      case 'browseServices':
        _keys(json, {'type', 'categoryId'});
        if (json.containsKey('categoryId') && json['categoryId'] == null) {
          throw const FormatException('Invalid category.');
        }
        return AssistantAction(
          type: AssistantActionType.browseServices,
          categoryId: json.containsKey('categoryId')
              ? _identifier(json['categoryId'])
              : null,
        );
      default:
        throw const FormatException('Unknown assistant action.');
    }
  }
}

class AssistantMessageModel {
  const AssistantMessageModel({
    required this.id,
    required this.role,
    required this.text,
    this.actions = const [],
  });
  final String id;
  final AssistantRole role;
  final String text;
  final List<AssistantAction> actions;
  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    _keys(json, {'id', 'role', 'text', 'actions'});
    final text = json['text'];
    final actions = json['actions'];
    if (json['role'] != 'assistant' ||
        text is! String ||
        text.trim().isEmpty ||
        text.length > 6000 ||
        actions is! List ||
        actions.length > 4) {
      throw const FormatException('Invalid assistant response.');
    }
    return AssistantMessageModel(
      id: _identifier(json['id']),
      role: AssistantRole.assistant,
      text: text,
      actions: List.unmodifiable(
        actions.map((action) {
          if (action is! Map<String, dynamic>) {
            throw const FormatException('Invalid assistant action.');
          }
          return AssistantAction.fromJson(action);
        }),
      ),
    );
  }
}
