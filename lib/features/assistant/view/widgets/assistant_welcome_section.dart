import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

class AssistantWelcomeSection extends StatelessWidget {
  const AssistantWelcomeSection({super.key, required this.onPrompt});
  final ValueChanged<String> onPrompt;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.horizontal(24),
        vertical: AppSize.vertical(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: AppSize.inset(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSize.radius(14)),
                border: Border.all(color: const Color(0xFF53634E)),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: AppSize.icon(30),
                color: AppColors.accent,
              ),
            ),
          ),
          SizedBox(height: AppSize.vertical(24)),
          Text(
            'A little guidance for\nyour next service.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppSize.vertical(16)),
          const Text(
            'Ask about AutoCare services. Messages are sent to Google Gemini and free-tier data may be used to improve products. Do not share names, emails, credentials, vehicle registrations or other personal information.',
            style: TextStyle(color: AppColors.secondary),
          ),
          SizedBox(height: AppSize.vertical(28)),
          for (final prompt in [
            'What is included in a full car wash?',
            'Which service is best before a long trip?',
            'What maintenance services fit my budget?',
          ])
            Padding(
              padding: EdgeInsets.only(bottom: AppSize.vertical(12)),
              child: OutlinedButton(
                onPressed: () => onPrompt(prompt),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(prompt),
                ),
              ),
            ),
          if (MediaQuery.textScalerOf(context).scale(16) > 22)
            const Text(
              'Service guidance only. A technician should inspect safety concerns.',
              style: TextStyle(color: AppColors.secondary),
            ),
        ],
      ),
    ),
  );
}
