import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';
import 'package:assessment_project_fb_international_frontend/core/widgets/responsive/adaptive_layout.dart';

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
          padding: padding ? AppSize.inset(desktop ? 28 : 16) : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// A single lazy viewport with the same bounded content width as PageContainer.
class PageSliverScrollView extends StatelessWidget {
  const PageSliverScrollView({
    super.key,
    required this.slivers,
    this.maxWidth,
    this.controller,
  });
  final List<Widget> slivers;
  final double? maxWidth;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = AppBreakpoints.isDesktop(
        MediaQuery.sizeOf(context).width,
      );
      final limit = desktop
          ? maxWidth ?? AppBreakpoints.desktopMaxWidth
          : (maxWidth ?? AppBreakpoints.compactMaxWidth)
                .clamp(0, AppBreakpoints.compactMaxWidth)
                .toDouble();
      final horizontal =
          ((constraints.maxWidth - limit) / 2).clamp(0, double.infinity) +
          AppSize.horizontal(desktop ? 28 : 16);
      return CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: AppSize.vertical(desktop ? 28 : 16),
            ),
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      );
    },
  );
}
