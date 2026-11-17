import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreHero extends StatelessWidget {
  const ExploreHero({super.key, required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(AppSize.radius(20)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 750;
        final text = Padding(
          padding: EdgeInsets.all(wide ? 36 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAR CARE, MADE SIMPLE',
                style: TextStyle(
                  fontSize: AppSize.font(12),
                  color: Color(0xFFF3BDAA),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: AppSize.vertical(16)),
              Text(
                'Expert care.\nReady when you are.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 38 : 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
              SizedBox(height: AppSize.vertical(16)),
              const Text(
                'From a fresh finish to everyday maintenance. Find your service and choose a time that works.',
                style: TextStyle(color: Color(0xFFD5DFEB), height: 1.6),
              ),
              SizedBox(height: AppSize.vertical(24)),
              FilledButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Explore services'),
              ),
            ],
          ),
        );
        final art = ExcludeSemantics(
          child: SizedBox(
            height: wide ? 300 : 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                      width: 30,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -.12,
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: wide ? 240 : 150,
                    color: const Color(0xFFE4EAF1),
                  ),
                ),
                Positioned(
                  bottom: wide ? 30 : 5,
                  child: Container(
                    width: 200,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSize.radius(20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return wide
            ? Row(
                children: [
                  Expanded(flex: 3, child: text),
                  Expanded(flex: 2, child: art),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [text, art],
              );
      },
    ),
  );
}
