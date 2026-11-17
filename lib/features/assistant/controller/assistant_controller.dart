import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_controller.dart';
import '../../shared/controller/catalog_controller.dart';
import '../model/assistant_message_model.dart';
import '../model/assistant_request_payload.dart';
import '../model/assistant_state.dart';
import '../service/assistant_service.dart';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

class AssistantController extends Notifier<AssistantState> {
  int _generation = 0;
  @override
  AssistantState build() {
    ref.watch(sessionProvider);
    _generation++;
    return const AssistantState();
  }

  Future<void> send(String text) async {
    final value = text.trim();
    if (value.isEmpty || state.sending || state.failedMessageId != null) return;
    final message = AssistantMessageModel(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      role: AssistantRole.user,
      text: value,
    );
    state = state.copyWith(
      messages: List.unmodifiable([...state.messages, message]),
      sending: true,
      clearError: true,
    );
    await _request(message.id);
  }

  Future<void> retry() async {
    if (state.sending || state.failedMessageId == null) return;
    final id = state.failedMessageId!;
    state = state.copyWith(sending: true, clearError: true);
    await _request(id);
  }

  void clear() {
    if (state.sending) return;
    _generation++;
    state = const AssistantState();
  }

  Future<void> _request(String messageId) async {
    final request = _generation;
    final session = ref.read(sessionProvider).asData?.value;
    // Watch once through the shared controller so recommendations resolve to the
    // same current service models used by Explore and booking.
    await ref.read(catalogControllerProvider.future);
    if (!ref.mounted ||
        request != _generation ||
        !identical(session, ref.read(sessionProvider).asData?.value)) {
      return;
    }
    final result = await ApiErrorHandler.run(
      () => ref
          .read(assistantServiceProvider)
          .send(AssistantRequestPayload(messages: state.messages)),
    );
    if (!ref.mounted ||
        request != _generation ||
        !identical(session, ref.read(sessionProvider).asData?.value)) {
      return;
    }
    if (!result.success) {
      state = state.copyWith(
        sending: false,
        errorCode: result.errorCode,
        failedMessageId: messageId,
      );
      return;
    }
    final catalog =
        ref.read(catalogControllerProvider).asData?.value.services ?? const [];
    final response = result.data!;
    final valid = response.actions
        .where(
          (action) => switch (action.type) {
            AssistantActionType.serviceDetails =>
              action.serviceId != null &&
                  catalog.any((s) => s.id == action.serviceId),
            AssistantActionType.browseServices =>
              action.categoryId == null ||
                  catalog.any((s) => s.categoryId == action.categoryId),
          },
        )
        .toList(growable: false);
    final safeMessage = AssistantMessageModel(
      id: response.id,
      role: AssistantRole.assistant,
      text: response.text,
      actions: List.unmodifiable(valid),
    );
    state = state.copyWith(
      messages: List.unmodifiable([...state.messages, safeMessage]),
      sending: false,
      clearError: true,
    );
  }
}
