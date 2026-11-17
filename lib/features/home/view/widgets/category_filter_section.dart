import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/home_controller.dart';

class CategoryFilterSection extends ConsumerWidget {
  const CategoryFilterSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(serviceCategoriesProvider);
    final controller = ref.watch(homeControllerProvider.notifier);
    final selected = ref.watch(
      homeControllerProvider.select((state) => state.categoryId),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All services'),
          selected: selected == null,
          onSelected: (_) => controller.category(null),
        ),
        for (final category in categories.entries)
          ChoiceChip(
            key: ValueKey(category.key),
            label: Text(category.value),
            selected: selected == category.key,
            onSelected: (_) => controller.category(category.key),
          ),
      ],
    );
  }
}
