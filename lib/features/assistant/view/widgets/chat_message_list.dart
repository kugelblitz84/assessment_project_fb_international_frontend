import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../controller/assistant_controller.dart';
import 'assistant_welcome_section.dart';
import 'chat_message_bubble.dart';

class ChatMessageList extends ConsumerWidget {
  const ChatMessageList({
    super.key,
    required this.controller,
    required this.onPrompt,
  });
  final ScrollController controller;
  final ValueChanged<String> onPrompt;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantControllerProvider);
    final recommendations = ref.watch(assistantRecommendationsProvider);
    if (state.messages.isEmpty) {
      return AssistantWelcomeSection(onPrompt: onPrompt);
    }
    return ListView.builder(
      controller: controller,
      padding: AppSize.inset(20),
      itemCount:
          state.messages.length +
          (state.sending || state.errorCode != null ? 1 : 0),
      findChildIndexCallback: (key) {
        final index = state.messages.indexWhere(
          (message) => ValueKey(message.id) == key,
        );
        return index < 0 ? null : index;
      },
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          return ChatMessageBubble(
            key: ValueKey(state.messages[index].id),
            message: state.messages[index],
            recommendations:
                recommendations[state.messages[index].id] ?? const [],
          );
        }
        if (state.errorCode != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InlineNotice(
                message: ApiErrorHandler.messageFor(state.errorCode),
                error: true,
              ),
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: ref
                        .read(assistantControllerProvider.notifier)
                        .retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry message'),
                  ),
                  TextButton(
                    onPressed: ref
                        .read(assistantControllerProvider.notifier)
                        .clear,
                    child: const Text('Start a new conversation'),
                  ),
                ],
              ),
            ],
          );
        }
        return Semantics(
          liveRegion: true,
          child: Padding(
            padding: AppSize.inset(16),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSize.horizontal(12)),
                Expanded(child: Text('AutoCare is thinking...')),
              ],
            ),
          ),
        );
      },
    );
  }
}
