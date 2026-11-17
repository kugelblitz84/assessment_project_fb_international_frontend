import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

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
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8EDF3), Color(0xFFD6E0EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: AppSize.icon(64),
        color: AppColors.navy.withValues(alpha: .6),
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
