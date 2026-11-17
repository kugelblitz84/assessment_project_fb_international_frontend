import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_depth.dart';

class ServiceImage extends StatelessWidget {
  const ServiceImage({
    super.key,
    this.url,
    required this.label,
    this.icon = Icons.car_repair_outlined,
  });
  final String? url;
  final String label;
  final IconData icon;

  IconData get _fallbackIcon {
    final name = label.toLowerCase();
    if (name.contains('wash') || name.contains('clean')) {
      return Icons.local_car_wash_outlined;
    }
    if (name.contains('interior') || name.contains('detail')) {
      return Icons.auto_awesome_outlined;
    }
    if (name.contains('oil')) return Icons.oil_barrel_outlined;
    if (name.contains('battery')) return Icons.battery_charging_full_rounded;
    if (name.contains('tyre') || name.contains('tire')) {
      return Icons.tire_repair_outlined;
    }
    if (name.contains('ac ') || name.contains('cool')) return Icons.ac_unit;
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDF0E8), Color(0xFFDDE3D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: AppSize.radius(130),
            height: AppSize.radius(130),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outline.withValues(alpha: .2),
              ),
            ),
          ),
          Container(
            padding: AppSize.inset(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSize.radius(14)),
              border: Border.all(color: AppColors.highlight),
              boxShadow: AppDepth.raised,
            ),
            child: Icon(
              _fallbackIcon,
              size: AppSize.icon(36),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: url == null
              ? fallback
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : fallback,
                  errorBuilder: (context, error, stack) => fallback,
                ),
        ),
      ),
    );
  }
}
