import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/formatters.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/app_surface.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/widgets/service_image.dart';
import 'package:assessment_project_fb_international_frontend/routes/app_routes.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service});
  final ServiceModel service;
  @override
  Widget build(BuildContext context) => AppSurface(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.serviceDetails,
        pathParameters: {'serviceId': service.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ServiceImage(url: service.imageUrl, label: service.name),
          Padding(
            padding: AppSize.inset(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.categoryName.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: AppSize.font(11),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: AppSize.vertical(10)),
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: AppSize.vertical(8)),
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.secondary),
                ),
                SizedBox(height: AppSize.vertical(16)),
                Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: AppSize.icon(16),
                      color: AppColors.secondary,
                    ),
                    Text(
                      Formatters.duration(service.durationMinutes),
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: AppSize.font(12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSize.vertical(12)),
                const Divider(height: 1),
                SizedBox(height: AppSize.vertical(12)),
                Text(
                  Formatters.price(service.price, service.currency),
                  style: TextStyle(
                    fontSize: AppSize.font(24),
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphite,
                  ),
                ),
                SizedBox(height: AppSize.vertical(8)),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'View details',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: AppSize.icon(18),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Lazy rows retain variable card heights for large text without nested scrolling.
class SliverServiceGrid extends StatelessWidget {
  const SliverServiceGrid({super.key, required this.services});
  final List<ServiceModel> services;
  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 21;
      final width = constraints.crossAxisExtent;
      final minWidth = width < 600 ? 156.0 : 250.0;
      final columns = largeText
          ? (width >= 820 ? 2 : 1)
          : ((width + 16) / (minWidth + 16)).floor().clamp(1, 4);
      return SliverList.builder(
        itemCount: (services.length / columns).ceil(),
        itemBuilder: (context, row) => Padding(
          padding: EdgeInsets.only(bottom: AppSize.vertical(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) SizedBox(width: AppSize.horizontal(16)),
                Expanded(
                  child: row * columns + column < services.length
                      ? ServiceCard(
                          key: ValueKey(services[row * columns + column].id),
                          service: services[row * columns + column],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
