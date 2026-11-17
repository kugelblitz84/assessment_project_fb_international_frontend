import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../../shared/controller/catalog_controller.dart';
import '../model/assistant_message_model.dart';
import '../model/assistant_request_payload.dart';
import '../model/assistant_state.dart';
import '../model/assistant_recommendation.dart';
import '../service/assistant_service.dart';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

class AssistantController extends Notifier<AssistantState> {
  int _generation = 0;
  @override
  AssistantState build() {
    ref.watch(sessionIdentityProvider);
    _generation++;
    return const AssistantState();
  }

  bool canSend(String text) =>
      text.trim().isNotEmpty &&
      text.trim().length <= 2000 &&
      !state.sending &&
      state.failedMessageId == null;

  /// Null means rejected; accepted sends update state synchronously.
  Future<void>? send(String text) {
    final value = text.trim();
    if (!canSend(value)) return null;
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
    return _request(message.id);
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
    final identity = ref.read(sessionIdentityProvider);
    // Watch once through the shared controller so recommendations resolve to the
    // same current service models used by Explore and booking.
    final catalogResult = await ApiErrorHandler.run(
      () => ref.read(catalogControllerProvider.future),
    );
    if (!ref.mounted ||
        request != _generation ||
        identity != ref.read(sessionIdentityProvider)) {
      return;
    }
    if (!catalogResult.success || catalogResult.data?.errorCode != null) {
      state = state.copyWith(
        sending: false,
        errorCode:
            catalogResult.errorCode ??
            catalogResult.data?.errorCode ??
            'INVALID_RESPONSE',
        failedMessageId: messageId,
      );
      return;
    }
    if (!ref.mounted ||
        request != _generation ||
        identity != ref.read(sessionIdentityProvider)) {
      return;
    }
    final result = await ApiErrorHandler.run(
      () => ref
          .read(assistantServiceProvider)
          .send(AssistantRequestPayload(messages: state.messages)),
    );
    if (!ref.mounted ||
        request != _generation ||
        identity != ref.read(sessionIdentityProvider)) {
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
    // Resolve cards against a fresh authoritative catalog after generation.
    await ApiErrorHandler.run(
      () => ref.read(catalogControllerProvider.notifier).refresh(),
    );
    if (!ref.mounted ||
        request != _generation ||
        identity != ref.read(sessionIdentityProvider)) {
      return;
    }
    final currentCatalog = ref.read(catalogControllerProvider).asData?.value;
    final response = result.data!;
    final valid = resolveRecommendations(
      response.actions,
      currentCatalog?.errorCode == null
          ? ref.read(catalogByIdProvider)
          : const {},
    ).map((recommendation) => recommendation.action).toList(growable: false);
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

final assistantRecommendationsProvider =
    Provider<Map<String, List<AssistantRecommendation>>>((ref) {
      final messages = ref.watch(
        assistantControllerProvider.select((state) => state.messages),
      );
      final catalog = ref.watch(catalogByIdProvider);
      return Map.unmodifiable({
        for (final message in messages)
          message.id: resolveRecommendations(message.actions, catalog),
      });
    });
