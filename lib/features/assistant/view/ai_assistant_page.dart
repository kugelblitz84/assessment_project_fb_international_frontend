import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/presentation/adaptive_app_shell.dart';
import '../../../core/responsive/adaptive_layout.dart';
import '../../../core/network/api_error_handler.dart';
import '../../../core/session/application/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../routes/app_routes.dart';
import '../../shared/controller/catalog_controller.dart';
import '../controller/assistant_controller.dart';
import '../model/assistant_message_model.dart';

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
    final state = ref.read(assistantControllerProvider);
    final text = prompt ?? _composer.text;
    if (text.trim().isEmpty || state.sending || state.failedMessageId != null) {
      return;
    }
    ref.read(assistantControllerProvider.notifier).send(text);
    _composer.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantControllerProvider);
    ref.watch(catalogControllerProvider);
    ref.listen(sessionProvider, (_, _) => _composer.clear());
    ref.listen(assistantControllerProvider, (previous, next) {
      final nearBottom =
          !_scroll.hasClients || _scroll.position.extentAfter < 140;
      if (nearBottom &&
          (next.messages.length != previous?.messages.length ||
              next.sending != previous?.sending)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    return AdaptiveAppShell(
      primary: true,
      title: 'AI assistant',
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width)
                ? 840
                : AppBreakpoints.compactMaxWidth,
          ),
          child: Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.primarySoft,
                                  child: Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 30,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'A little guidance for\nyour next service.',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Ask AutoCare about car services, prices, or what your car may need.',
                                style: TextStyle(color: AppColors.secondary),
                              ),
                              const SizedBox(height: 28),
                              for (final prompt in [
                                'What is included in a full car wash?',
                                'Which service is best before a long trip?',
                                'What maintenance services fit my budget?',
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: OutlinedButton(
                                    onPressed: () => _send(prompt),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(prompt),
                                    ),
                                  ),
                                ),
                              if (MediaQuery.textScalerOf(context).scale(16) >
                                  22)
                                const Text(
                                  'Service guidance only. A technician should inspect safety concerns.',
                                  style: TextStyle(color: AppColors.secondary),
                                ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(20),
                        itemCount:
                            state.messages.length +
                            (state.sending || state.errorCode != null ? 1 : 0),
                        itemBuilder: (context, index) =>
                            index == state.messages.length
                            ? state.errorCode != null
                                  ? _errorMessage(state.errorCode!)
                                  : Semantics(
                                      liveRegion: true,
                                      child: const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'AutoCare is thinking…',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                            : _bubble(state.messages[index]),
                      ),
              ),
              Material(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.enter &&
                                      !HardwareKeyboard
                                          .instance
                                          .isShiftPressed) {
                                    _send();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextField(
                                  controller: _composer,
                                  focusNode: _focus,
                                  minLines: 1,
                                  maxLines:
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(16) >
                                          22
                                      ? 2
                                      : 4,
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
                            const SizedBox(width: 8),
                            ValueListenableBuilder(
                              valueListenable: _composer,
                              builder: (context, value, _) => IconButton.filled(
                                tooltip: 'Send message',
                                onPressed:
                                    state.sending ||
                                        state.failedMessageId != null ||
                                        value.text.trim().isEmpty
                                    ? null
                                    : _send,
                                icon: const Icon(Icons.arrow_upward),
                              ),
                            ),
                          ],
                        ),
                        if (MediaQuery.viewInsetsOf(context).bottom == 0 &&
                            MediaQuery.textScalerOf(context).scale(16) <=
                                22) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Service guidance only. A technician should inspect safety concerns.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorMessage(String code) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InlineNotice(message: ApiErrorHandler.messageFor(code), error: true),
      Wrap(
        children: [
          TextButton.icon(
            onPressed: ref.read(assistantControllerProvider.notifier).retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry message'),
          ),
          TextButton(
            onPressed: ref.read(assistantControllerProvider.notifier).clear,
            child: const Text('Start a new conversation'),
          ),
        ],
      ),
    ],
  );

  Widget _bubble(AssistantMessageModel message) {
    final user = message.role == AssistantRole.user;
    final catalog =
        ref.watch(catalogControllerProvider).asData?.value.services ?? const [];
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        margin: EdgeInsets.only(
          bottom: 20,
          left: user ? 28 : 0,
          right: user ? 0 : 20,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: user ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: user ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user ? 'YOU' : 'AUTOCARE',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(message.text),
            for (final action in message.actions) ...[
              const SizedBox(height: 12),
              if (action.type == AssistantActionType.serviceDetails &&
                  catalog.any((s) => s.id == action.serviceId))
                Builder(
                  builder: (context) {
                    final service = catalog.firstWhere(
                      (s) => s.id == action.serviceId,
                    );
                    return OutlinedButton(
                      onPressed: () => context.pushNamed(
                        AppRoutes.serviceDetails,
                        pathParameters: {'serviceId': service.id},
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${Formatters.price(service.price, service.currency)} · ${Formatters.duration(service.durationMinutes)}',
                            ),
                            const SizedBox(height: 4),
                            const Text('View service →'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (action.type == AssistantActionType.browseServices)
                TextButton.icon(
                  onPressed: () {
                    context.goNamed(
                      AppRoutes.home,
                      queryParameters: {
                        'browse': 'all',
                        if (action.categoryId != null)
                          'category': action.categoryId!,
                      },
                    );
                  },
                  icon: const Icon(Icons.grid_view_outlined),
                  label: const Text('Browse services'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
