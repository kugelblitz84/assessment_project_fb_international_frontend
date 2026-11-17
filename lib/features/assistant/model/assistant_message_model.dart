enum AssistantRole { user, assistant }

enum AssistantActionType { serviceDetails, browseServices }

class AssistantAction {
  const AssistantAction({required this.type, this.serviceId, this.categoryId});
  final AssistantActionType type;
  final String? serviceId;
  final String? categoryId;
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
}
