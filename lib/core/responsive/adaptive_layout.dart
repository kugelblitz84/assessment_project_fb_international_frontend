import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const desktop = 900.0;
  static const compactMaxWidth = 560.0;
  static const desktopMaxWidth = 1200.0;
  static bool isDesktop(double width) => width >= desktop;
}

/// Changes composition without owning any form or feature state.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({super.key, required this.main, required this.aside});
  final Widget main;
  final Widget aside;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 820 ||
          MediaQuery.textScalerOf(context).scale(16) > 25) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [main, const SizedBox(height: 24), aside],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: main),
          const SizedBox(width: 32),
          SizedBox(width: 340, child: aside),
        ],
      );
    },
  );
}
