import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_depth.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/features/home/controller/home_controller.dart';

class ServiceSearchBar extends ConsumerWidget {
  const ServiceSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onFilters,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onFilters;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeController = ref.watch(homeControllerProvider.notifier);
    final empty = ref.watch(
      homeControllerProvider.select((state) => state.query.isEmpty),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: homeController.search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search services',
              hintText: 'Try oil change or car wash',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: empty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () => homeController.search(''),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        SizedBox(width: AppSize.horizontal(8)),
        SizedBox(
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.radius(10)),
              boxShadow: AppDepth.control,
            ),
            child: IconButton.outlined(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.highlight),
              ),
              tooltip: 'Filter services',
              onPressed: onFilters,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
