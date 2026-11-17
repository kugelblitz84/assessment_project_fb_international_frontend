import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../network/api_error_handler.dart';
import '../theme/app_colors.dart';

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.action,
  });
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.horizontal(16),
        vertical: AppSize.vertical(32),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSize.inset(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSize.icon(36),
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSize.vertical(20)),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSize.vertical(8)),
            Text(
              message,
              style: const TextStyle(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              SizedBox(height: AppSize.vertical(20)),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.code, required this.onRetry});
  final String? code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => StateMessage(
    title: code == 'NOT_FOUND' ? 'We couldn’t find that' : 'Unable to load',
    message: ApiErrorHandler.messageFor(code),
    icon: Icons.cloud_off_outlined,
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Try again'),
    ),
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading…'});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: AppSize.inset(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: AppSize.vertical(16)),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({super.key, required this.message, this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: AppSize.inset(16),
      decoration: BoxDecoration(
        color: error ? AppColors.errorSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSize.radius(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : Icons.info_outline,
            size: AppSize.icon(20),
            color: error ? AppColors.error : AppColors.primary,
          ),
          SizedBox(width: AppSize.horizontal(10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: error ? AppColors.error : AppColors.text),
            ),
          ),
        ],
      ),
    ),
  );
}
