import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Resolution independent automotive artwork, kept local for fast, offline UI.
class PerformanceCarArt extends StatelessWidget {
  const PerformanceCarArt({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(
    painter: _PerformanceCarPainter(),
    child: SizedBox.expand(),
  );
}

class _PerformanceCarPainter extends CustomPainter {
  const _PerformanceCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 520, size.height / 260);
    canvas.save();
    canvas.translate(
      (size.width - 520 * scale) / 2,
      (size.height - 260 * scale) / 2,
    );
    canvas.scale(scale);

    final guide = Paint()
      ..color = const Color(0xFF445144)
      ..strokeWidth = .6;
    for (var x = 30.0; x < 520; x += 40) {
      canvas.drawLine(Offset(x, 30), Offset(x, 240), guide);
    }
    for (var y = 40.0; y < 260; y += 40) {
      canvas.drawLine(Offset(20, y), Offset(500, y), guide);
    }
    canvas.drawCircle(
      const Offset(276, 139),
      112,
      Paint()
        ..color = const Color(0xFF526047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    canvas.drawArc(
      const Rect.fromLTWH(164, 27, 224, 224),
      -2.8,
      .65,
      false,
      Paint()
        ..color = AppColors.accent.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      const Rect.fromLTWH(44, 205, 440, 20),
      Paint()
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final body = Path()
      ..moveTo(34, 179)
      ..lineTo(40, 158)
      ..quadraticBezierTo(46, 149, 79, 144)
      ..lineTo(146, 132)
      ..cubicTo(174, 105, 199, 87, 229, 85)
      ..cubicTo(267, 80, 303, 85, 328, 101)
      ..lineTo(375, 132)
      ..cubicTo(420, 134, 459, 141, 478, 154)
      ..quadraticBezierTo(491, 160, 490, 177)
      ..lineTo(484, 192)
      ..lineTo(448, 194)
      ..cubicTo(443, 143, 371, 143, 365, 194)
      ..lineTo(177, 194)
      ..cubicTo(172, 143, 101, 143, 96, 194)
      ..lineTo(48, 190)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F2E9), Color(0xFFAAB6A7), Color(0xFF657660)],
          stops: [0, .45, 1],
        ).createShader(const Rect.fromLTWH(30, 84, 460, 115)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFE1E6D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );

    final glass = Path()
      ..moveTo(166, 131)
      ..quadraticBezierTo(203, 96, 231, 94)
      ..quadraticBezierTo(282, 87, 316, 107)
      ..lineTo(350, 132)
      ..close();
    canvas.drawPath(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF526656), Color(0xFF18261E)],
        ).createShader(const Rect.fromLTWH(166, 90, 184, 43)),
    );
    final detail = Paint()
      ..color = const Color(0xFF56694F)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      const Offset(263, 94),
      const Offset(267, 132),
      detail..strokeWidth = 5,
    );
    canvas.drawPath(
      Path()
        ..moveTo(276, 138)
        ..lineTo(278, 173)
        ..quadraticBezierTo(278, 183, 289, 183)
        ..lineTo(355, 183)
        ..lineTo(358, 139),
      detail..strokeWidth = .8,
    );
    canvas.drawLine(const Offset(64, 151), const Offset(454, 151), detail);
    canvas.drawLine(
      const Offset(187, 187),
      const Offset(354, 187),
      detail..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(290, 141, 18, 3),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF53634E),
    );
    canvas.drawPath(
      Path()
        ..moveTo(339, 127)
        ..quadraticBezierTo(359, 118, 365, 130)
        ..lineTo(348, 134)
        ..close(),
      Paint()..color = const Color(0xFFDAE1D1),
    );
    canvas.drawLine(
      const Offset(459, 154),
      const Offset(480, 159),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(43, 156),
      const Offset(62, 153),
      Paint()
        ..color = const Color(0xFFBA7765)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      const Offset(459, 178),
      const Offset(486, 177),
      Paint()
        ..color = const Color(0xFF263727)
        ..strokeWidth = 5,
    );

    for (final x in [136.0, 407.0]) {
      final center = Offset(x, 188);
      canvas.drawCircle(center, 35, Paint()..color = const Color(0xFF141D17));
      canvas.drawCircle(
        center,
        29,
        Paint()
          ..color = const Color(0xFF52614F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawCircle(center, 24, Paint()..color = const Color(0xFF7C8875));
      canvas.drawCircle(center, 20, Paint()..color = const Color(0xFF2C3A2B));
      canvas.drawLine(
        Offset(x + 15, 181),
        Offset(x + 15, 193),
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 4,
      );
      for (var spoke = 0; spoke < 5; spoke++) {
        final angle = spoke * math.pi * 2 / 5 - .4;
        for (final offset in [-.1, .1]) {
          canvas.drawLine(
            center + Offset(math.cos(angle) * 6, math.sin(angle) * 6),
            center +
                Offset(
                  math.cos(angle + offset) * 22,
                  math.sin(angle + offset) * 22,
                ),
            Paint()
              ..color = const Color(0xFFCDD5C4)
              ..strokeWidth = 2.2,
          );
        }
      }
      canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFBCC8B2));
      canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF43553D));
    }

    // Short calibration marks reinforce the workshop drawing aesthetic.
    final mark = Paint()
      ..color = AppColors.accent.withValues(alpha: .7)
      ..strokeWidth = 1;
    for (final x in [36.0, 484.0]) {
      canvas.drawLine(Offset(x - 4, 233), Offset(x + 4, 233), mark);
      canvas.drawLine(Offset(x, 229), Offset(x, 237), mark);
    }
    canvas.drawLine(const Offset(52, 233), const Offset(468, 233), guide);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PerformanceCarPainter oldDelegate) => false;
}
