import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/adaptive_layout.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../controller/assistant_controller.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_list.dart';

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
    final pending = ref
        .read(assistantControllerProvider.notifier)
        .send(prompt ?? _composer.text);
    if (pending == null) return;
    _composer.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionIdentityProvider, (_, _) => _composer.clear());
    ref.listen(assistantControllerProvider, (previous, next) {
      final nearBottom =
          !_scroll.hasClients || _scroll.position.extentAfter < 140;
      if (nearBottom &&
          (next.messages.length != previous?.messages.length ||
              next.sending != previous?.sending)) {
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
    });
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
