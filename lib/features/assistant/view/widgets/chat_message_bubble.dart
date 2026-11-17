import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_depth.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../../home/controller/home_controller.dart';
import '../../model/assistant_message_model.dart';
import '../../model/assistant_recommendation.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.recommendations,
  });
  final AssistantMessageModel message;
  final List<AssistantRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final user = message.role == AssistantRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        margin: EdgeInsets.only(
          bottom: AppSize.vertical(20),
          left: user ? AppSize.horizontal(28) : 0,
          right: user ? 0 : AppSize.horizontal(20),
        ),
        padding: AppSize.inset(18),
        decoration: BoxDecoration(
          color: user ? AppColors.primarySoft : AppColors.surface,
          borderRadius: AppSize.cardRadius,
          border: Border.all(
            color: user ? AppColors.border : AppColors.highlight,
          ),
          boxShadow: user ? null : AppDepth.control,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user ? 'YOU' : 'AUTOCARE',
              style: TextStyle(
                fontSize: AppSize.font(11),
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSize.vertical(8)),
            SelectableText(message.text),
            for (final recommendation in recommendations) ...[
              SizedBox(height: AppSize.vertical(12)),
              AssistantRecommendationCard(recommendation: recommendation),
            ],
          ],
        ),
      ),
    );
  }
}

class AssistantRecommendationCard extends ConsumerWidget {
  const AssistantRecommendationCard({super.key, required this.recommendation});
  final AssistantRecommendation recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = recommendation.service;
    if (service == null) {
      return TextButton.icon(
        onPressed: () {
          // Repeating the same recommendation is still an explicit browse intent.
          ref
              .read(homeControllerProvider.notifier)
              .browse(recommendation.action.categoryId);
          context.goNamed(
            AppRoutes.home,
            queryParameters: {
              'browse': 'all',
              if (recommendation.action.categoryId != null)
                'category': recommendation.action.categoryId!,
            },
          );
        },
        icon: const Icon(Icons.grid_view_outlined),
        label: const Text('Browse services'),
      );
    }
    return OutlinedButton(
      onPressed: () => context.pushNamed(
        AppRoutes.serviceDetails,
        pathParameters: {'serviceId': service.id},
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.vertical(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              service.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSize.vertical(4)),
            Text(
              '${Formatters.price(service.price, service.currency)} · ${Formatters.duration(service.durationMinutes)}',
            ),
            SizedBox(height: AppSize.vertical(4)),
            const Text('View service →'),
          ],
        ),
      ),
    );
  }
}
