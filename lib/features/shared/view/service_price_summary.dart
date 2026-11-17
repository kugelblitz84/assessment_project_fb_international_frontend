import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../model/service_model.dart';

class ServicePriceSummary extends StatelessWidget {
  const ServicePriceSummary({
    super.key,
    required this.service,
    this.children = const [],
    this.action,
  });
  final ServiceModel service;
  final List<Widget> children;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: AppSize.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOUR SERVICE',
            style: TextStyle(
              fontSize: AppSize.font(12),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: AppSize.vertical(12)),
          Text(service.name, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppSize.vertical(12)),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.schedule_outlined,
                size: AppSize.icon(18),
                color: AppColors.secondary,
              ),
              Text(
                Formatters.duration(service.durationMinutes),
                style: const TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            SizedBox(height: AppSize.vertical(20)),
            const Divider(),
            SizedBox(height: AppSize.vertical(12)),
            ...children,
          ],
          SizedBox(height: AppSize.vertical(20)),
          const Divider(),
          SizedBox(height: AppSize.vertical(12)),
          const Text(
            'Service price',
            style: TextStyle(color: AppColors.secondary),
          ),
          SizedBox(height: AppSize.vertical(4)),
          Text(
            Formatters.price(service.price, service.currency),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppSize.vertical(8)),
          const Text(
            'Review your appointment before booking.',
            style: TextStyle(color: AppColors.secondary),
          ),
          if (action != null) ...[
            SizedBox(height: AppSize.vertical(20)),
            action!,
          ],
        ],
      ),
    ),
  );
}
