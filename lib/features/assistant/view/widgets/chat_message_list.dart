import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/app/api_error_messages.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/async_state_view.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/view/widgets/assistant_welcome_section.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/view/widgets/chat_message_bubble.dart';

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
    final assistant = ref.watch(assistantControllerProvider.notifier);
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
                message: AppErrorMessages.messageFor(state.errorCode),
                error: true,
              ),
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: assistant.retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry message'),
                  ),
                  TextButton(
                    onPressed: assistant.clear,
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
