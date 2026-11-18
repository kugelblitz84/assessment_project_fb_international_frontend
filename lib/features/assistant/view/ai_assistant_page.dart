import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/session/presentation/provider/session_identity_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/responsive/adaptive_layout.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_state.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/view/widgets/chat_composer.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/view/widgets/chat_message_list.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});
  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? prompt]) {
    final assistant = ref.read(assistantControllerProvider.notifier);
    if (assistant.send(prompt ?? _composer.text) == null) return;
    _composer.clear();
    _focus.requestFocus();
  }

  void _onConversationChanged(AssistantState? previous, AssistantState next) {
    final nearBottom =
        !_scroll.hasClients || _scroll.position.extentAfter < 140;
    final changed =
        next.messages.length != previous?.messages.length ||
        next.sending != previous?.sending;
    if (!nearBottom || !changed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The indexed stack disables tickers for inactive branches.
      if (mounted &&
          TickerMode.getValuesNotifier(context).value.enabled &&
          _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionIdentityProvider, (_, _) => _composer.clear());
    ref.listen(assistantControllerProvider, _onConversationChanged);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width)
              ? 840
              : AppBreakpoints.compactMaxWidth,
        ),
        child: Column(
          children: [
            Expanded(
              child: ChatMessageList(controller: _scroll, onPrompt: _send),
            ),
            ChatComposer(
              controller: _composer,
              focusNode: _focus,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}
