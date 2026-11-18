import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/section_header.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/controller/catalog_controller.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/view/widgets/service_card.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';

/// Shares the catalogue's loading, refresh, and error lifecycle.
class FeaturedServicesSection extends ConsumerWidget {
  const FeaturedServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(
      homeControllerProvider.select((state) => state.filtered),
    );
    final services = ref.watch(featuredServicesProvider);
    if (filtered || services.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Featured services',
            subtitle: 'Selected care for your next drive.',
          ),
        ),
        SliverServiceGrid(services: services),
        SliverToBoxAdapter(child: SizedBox(height: AppSize.vertical(16))),
      ],
    );
  }
}
