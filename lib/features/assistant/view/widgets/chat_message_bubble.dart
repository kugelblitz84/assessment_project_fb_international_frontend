import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_depth.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_recommendation.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/widgets/service_image.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

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

class AssistantRecommendationCard extends StatelessWidget {
  const AssistantRecommendationCard({super.key, required this.recommendation});
  final AssistantRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final service = recommendation.service;
    if (service == null) {
      return TextButton.icon(
        onPressed: () {
          context.go(
            AppRoutes.browseServicesLocation(recommendation.action.categoryId),
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
            if (service.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ServiceImage(url: service.imageUrl, label: service.name),
              ),
              SizedBox(height: AppSize.vertical(8)),
            ],
            Text(
              service.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSize.vertical(4)),
            Text(
              '${Formatters.price(service.price, service.currency)} · ${Formatters.duration(service.durationMinutes)}',
            ),
            SizedBox(height: AppSize.vertical(4)),
            if (service.originalPrice != null &&
                service.originalPrice! > service.price)
              Text(
                Formatters.price(service.originalPrice!, service.currency),
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
            Text(service.isPackage ? 'View package →' : 'View service →'),
          ],
        ),
      ),
    );
  }
}
