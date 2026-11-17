import '../../shared/model/service_model.dart';
import 'assistant_message_model.dart';

class AssistantRecommendation {
  const AssistantRecommendation({required this.action, this.service});
  final AssistantAction action;
  final ServiceModel? service;
}

List<AssistantRecommendation> resolveRecommendations(
  List<AssistantAction> actions,
  Map<String, ServiceModel> catalog,
) {
  final categories = catalog.values
      .map((service) => service.categoryId)
      .toSet();
  return List.unmodifiable([
    for (final action in actions)
      if (action.type == AssistantActionType.serviceDetails &&
          catalog.containsKey(action.serviceId))
        AssistantRecommendation(
          action: action,
          service: catalog[action.serviceId],
        )
      else if (action.type == AssistantActionType.browseServices &&
          (action.categoryId == null || categories.contains(action.categoryId)))
        AssistantRecommendation(action: action),
  ]);
}
