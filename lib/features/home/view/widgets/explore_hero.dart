import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_depth.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/performance_car_art.dart';

class ExploreHero extends StatelessWidget {
  const ExploreHero({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: AppSize.cardRadius,
      boxShadow: AppDepth.raised,
    ),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppSize.cardRadius,
        border: Border.all(color: const Color(0xFF4A564B)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF344036), AppColors.graphite, Color(0xFF18201B)],
          stops: [0, .6, 1],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 750;
          final copy = Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 36 : 24,
              wide ? 32 : 26,
              wide ? 16 : 24,
              wide ? 32 : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 18, height: 3, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'CARE. TUNED TO YOU.',
                        style: TextStyle(
                          fontSize: AppSize.font(10),
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSize.vertical(18)),
                Text(
                  'Every detail.\nA better drive.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.surface,
                    fontSize: AppSize.font(wide ? 46 : 34),
                  ),
                ),
                SizedBox(height: AppSize.vertical(14)),
                const Text(
                  'From a fresh finish to everyday maintenance. Your next service, on your schedule.',
                  style: TextStyle(color: Color(0xFFBCC7BB), height: 1.6),
                ),
                SizedBox(height: AppSize.vertical(24)),
                FilledButton(
                  onPressed: onExplore,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shadowColor: Colors.black.withValues(alpha: .25),
                  ),
                  child: const Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    children: [
                      Text('Explore services'),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          );
          final art = ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.fromLTRB(wide ? 0 : 12, 12, 12, 12),
              child: Column(
                children: [
                  SizedBox(
                    height: wide ? 224 : 110,
                    width: double.infinity,
                    child: const PerformanceCarArt(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSize.horizontal(24),
                      vertical: AppSize.vertical(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFF4A564B)),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 2,
                          child: Text(
                            'PRECISION IN EVERY DETAIL',
                            style: TextStyle(
                              fontSize: AppSize.font(8),
                              letterSpacing: 1.4,
                              color: const Color(0xFF9BA998),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          return wide
              ? Row(
                  children: [
                    Expanded(child: copy),
                    Expanded(child: art),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [copy, art],
                );
        },
      ),
    ),
  );
}
