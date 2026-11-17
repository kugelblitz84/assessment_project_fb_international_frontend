import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../controller/admin_providers.dart';

class AdminAsync<T> extends StatelessWidget {
  const AdminAsync({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: true,
    data: builder,
    loading: () => const LoadingState(),
    error: (error, _) => ErrorState(
      code: error is AdminFailure ? error.code : 'UNEXPECTED_ERROR',
      onRetry: onRetry,
    ),
  );
}

Future<bool> adminConfirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep unchanged'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

void adminNotice(
  BuildContext context,
  ApiResponse<void> result, {
  String success = 'Changes saved.',
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.success ? success : ApiErrorHandler.messageFor(result.errorCode),
      ),
    ),
  );
}

class AdminPageBody extends StatelessWidget {
  const AdminPageBody({super.key, required this.children, this.form = false});
  final List<Widget> children;
  final bool form;
  @override
  Widget build(BuildContext context) => form
      ? SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              // Keep every FormField mounted so validation includes fields that
              // have scrolled out of view, including on small mobile screens.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: child,
                    ),
                ],
              ),
            ),
          ),
        )
      : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final child in children)
              Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
          ],
        );
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty({super.key});
  @override
  Widget build(BuildContext context) => const StateMessage(
    title: 'No items found',
    message: 'Add an item or adjust your filters.',
  );
}
