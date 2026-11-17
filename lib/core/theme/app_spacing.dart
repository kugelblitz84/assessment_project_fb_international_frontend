import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract final class AppSize {
  static double gap(double value) =>
      value.w.clamp(value * .9, value * 1.15).toDouble();
  static double radius(double value) =>
      value.r.clamp(value * .9, value * 1.15).toDouble();
}
