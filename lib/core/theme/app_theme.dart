import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.navy,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.error,
      outline: AppColors.outline,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.navy,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: AppSize.font(38),
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: AppSize.font(28),
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: AppSize.font(22),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: AppSize.font(17),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: text.bodyLarge?.copyWith(
          fontSize: AppSize.font(16),
          height: 1.5,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          fontSize: AppSize.font(14),
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(48, AppSize.controlHeight(52)),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(24),
            vertical: AppSize.vertical(14),
          ),
          textStyle: text.labelLarge?.copyWith(
            fontSize: AppSize.font(15),
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.radius(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(48, AppSize.controlHeight(52)),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(20),
            vertical: AppSize.vertical(14),
          ),
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.radius(12)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(16),
            vertical: AppSize.vertical(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSize.horizontal(16),
          vertical: AppSize.vertical(18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.radius(12)),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.radius(12)),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.radius(12)),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSize.cardRadius,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.outline),
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.horizontal(8),
          vertical: AppSize.vertical(12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.radius(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: AppSize.font(12),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.secondary,
          ),
        ),
      ),
      dividerColor: AppColors.border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
