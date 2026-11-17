import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A soft lower shadow and an upper highlight suggest machined, raised surfaces.
abstract final class AppDepth {
  static const raised = [
    BoxShadow(color: Color(0x45B6C0B4), offset: Offset(5, 7), blurRadius: 18),
    BoxShadow(color: Color(0xD9FFFFFF), offset: Offset(-4, -4), blurRadius: 12),
  ];

  static const control = [
    BoxShadow(color: Color(0x55B6C0B4), offset: Offset(2, 3), blurRadius: 6),
    BoxShadow(
      color: AppColors.highlight,
      offset: Offset(-2, -2),
      blurRadius: 5,
    ),
  ];

  static const floating = [
    BoxShadow(color: Color(0x24B6C0B4), offset: Offset(0, -4), blurRadius: 16),
  ];
}
