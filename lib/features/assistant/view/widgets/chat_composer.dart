import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_depth.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/controller/assistant_controller.dart';

class ChatComposer extends ConsumerWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistant = ref.watch(assistantControllerProvider.notifier);
    ref.watch(
      assistantControllerProvider.select(
        (state) => (state.sending, state.failedMessageId),
      ),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppDepth.floating),
      child: Material(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.horizontal(16),
              vertical: AppSize.vertical(12),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter &&
                              !HardwareKeyboard.instance.isShiftPressed) {
                            onSend();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: largeText ? 2 : 4,
                          maxLength: 2000,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            labelText: 'Ask AutoCare',
                            hintText: 'How can we help your car?',
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSize.horizontal(8)),
                    ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, value, _) => IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: assistant.canSend(value.text)
                            ? onSend
                            : null,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    ),
                  ],
                ),
                if (MediaQuery.viewInsetsOf(context).bottom == 0 &&
                    !largeText) ...[
                  SizedBox(height: AppSize.vertical(8)),
                  Text(
                    'Service guidance only. A technician should inspect safety concerns.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: AppSize.font(11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
