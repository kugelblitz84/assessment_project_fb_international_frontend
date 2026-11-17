import 'package:flutter/material.dart';

import '../responsive/adaptive_layout.dart';
import '../theme/app_spacing.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding = true,
  });
  final Widget child;
  final double? maxWidth;
  final bool padding;

  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: desktop
              ? maxWidth ?? AppBreakpoints.desktopMaxWidth
              : (maxWidth ?? AppBreakpoints.compactMaxWidth)
                    .clamp(0, AppBreakpoints.compactMaxWidth)
                    .toDouble(),
        ),
        child: Padding(
          padding: padding
              ? EdgeInsets.all(AppSize.gap(desktop ? 28 : 16))
              : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
