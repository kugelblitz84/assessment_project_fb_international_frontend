import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Scale small dimensions from the mobile design without stretching desktop UI.
/// Breakpoints, content limits, aspect ratios, and minimum touch targets stay fixed.
abstract final class AppSize {
  static double horizontal(double value) =>
      value.w.clamp(value * .9, value * 1.15).toDouble();
  static double vertical(double value) =>
      value.h.clamp(value * .9, value * 1.15).toDouble();
  static double radius(double value) =>
      value.r.clamp(value * .9, value * 1.15).toDouble();
  static double font(double value) =>
      value.sp.clamp(value * .95, value * 1.1).toDouble();
  static double icon(double value) => radius(value);
  static double controlHeight(double value) =>
      vertical(value).clamp(48, double.infinity).toDouble();
  static EdgeInsets inset(double value) => EdgeInsets.symmetric(
    horizontal: horizontal(value),
    vertical: vertical(value),
  );
  static EdgeInsets get cardPadding => inset(24);
  static BorderRadius get cardRadius => BorderRadius.circular(radius(16));
}
