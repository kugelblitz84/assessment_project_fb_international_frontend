import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../controller/home_controller.dart';

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
            onChanged: ref.read(homeControllerProvider.notifier).search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search services',
              hintText: 'Try oil change or car wash',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: empty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () =>
                          ref.read(homeControllerProvider.notifier).search(''),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        SizedBox(width: AppSize.horizontal(8)),
        SizedBox(
          height: 60,
          child: IconButton.outlined(
            tooltip: 'Filter services',
            onPressed: onFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}
