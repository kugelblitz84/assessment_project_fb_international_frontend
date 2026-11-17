import 'package:flutter/material.dart';
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
        style: const TextStyle(
          fontSize: 20,
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      );
      if (constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [total, const SizedBox(height: 8), action],
        );
      }
      return Row(
        children: [
          Flexible(child: total),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: action),
        ],
      );
    },
  );
}
