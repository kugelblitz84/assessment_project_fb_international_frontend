import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'category_filter_section.dart';

class ServiceFilterSheet extends StatelessWidget {
  const ServiceFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const ServiceFilterSheet(),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: AppSize.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: AppSize.vertical(20)),
            const CategoryFilterSection(),
            SizedBox(height: AppSize.vertical(24)),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Show services'),
            ),
          ],
        ),
      ),
    ),
  );
}
