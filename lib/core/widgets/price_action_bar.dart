import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

class PriceActionBar extends StatelessWidget {
  const PriceActionBar({super.key, required this.price, required this.action});
  final String price;
  final Widget action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final total = Text(
        price,
        style: TextStyle(
          fontSize: AppSize.font(20),
          color: AppColors.graphite,
          fontWeight: FontWeight.w700,
        ),
      );
      if (constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            total,
            SizedBox(height: AppSize.vertical(8)),
            action,
          ],
        );
      }
      return Row(
        children: [
          Flexible(child: total),
          SizedBox(width: AppSize.horizontal(16)),
          Expanded(flex: 2, child: action),
        ],
      );
    },
  );
}
