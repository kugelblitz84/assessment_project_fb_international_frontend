import 'package:flutter/material.dart';

import 'package:assessment_project_fb_international_frontend/core/theme/app_colors.dart';
import 'package:assessment_project_fb_international_frontend/core/theme/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primary,
      secondaryContainer: AppColors.primarySoft,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.onAccent,
      tertiaryContainer: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.secondary,
      surfaceContainerHighest: AppColors.surfaceRecessed,
      error: AppColors.error,
      outline: AppColors.outline,
      outlineVariant: AppColors.border,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.graphite,
    );
    final controlRadius = BorderRadius.circular(AppSize.radius(10));
    final controlShape = RoundedRectangleBorder(borderRadius: controlRadius);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      shadowColor: AppColors.shadow,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontFamily: 'RobotoCondensed',
          fontSize: AppSize.font(40),
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
          height: 1.08,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontFamily: 'RobotoCondensed',
          fontSize: AppSize.font(30),
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
          height: 1.15,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontFamily: 'RobotoCondensed',
          fontSize: AppSize.font(23),
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: AppSize.font(16),
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        bodyLarge: text.bodyLarge?.copyWith(
          fontSize: AppSize.font(16),
          height: 1.55,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          fontSize: AppSize.font(14),
          height: 1.5,
        ),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: .15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.graphite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontFamily: 'RobotoCondensed',
          fontSize: AppSize.font(23),
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(48, AppSize.controlHeight(52)),
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(24),
            vertical: AppSize.vertical(14),
          ),
          elevation: 2,
          shadowColor: AppColors.shadow.withValues(alpha: .5),
          textStyle: text.labelLarge?.copyWith(
            fontSize: AppSize.font(14),
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(48, AppSize.controlHeight(52)),
          backgroundColor: AppColors.surface,
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(20),
            vertical: AppSize.vertical(14),
          ),
          side: const BorderSide(color: AppColors.border),
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: controlShape,
          padding: EdgeInsets.symmetric(
            horizontal: AppSize.horizontal(16),
            vertical: AppSize.vertical(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: controlShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRecessed,
        labelStyle: const TextStyle(color: AppColors.secondary),
        hintStyle: const TextStyle(color: AppColors.secondary),
        prefixIconColor: AppColors.secondary,
        suffixIconColor: AppColors.secondary,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSize.horizontal(16),
          vertical: AppSize.vertical(18),
        ),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: AppColors.shadow.withValues(alpha: .35),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSize.cardRadius,
          side: const BorderSide(color: AppColors.highlight),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceRecessed,
        checkmarkColor: AppColors.accent,
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppSize.font(12),
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: AppSize.font(12),
          fontWeight: FontWeight.w700,
          color: AppColors.surface,
        ),
        side: BorderSide.none,
        elevation: 1,
        pressElevation: 0,
        shadowColor: AppColors.shadow.withValues(alpha: .45),
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.horizontal(10),
          vertical: AppSize.vertical(10),
        ),
        shape: controlShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary,
        indicatorShape: controlShape,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSize.icon(21),
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.secondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: AppSize.font(11),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.secondary,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.secondary,
        textColor: AppColors.text,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.graphite,
        contentTextStyle: const TextStyle(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceRecessed,
      ),
    );
  }
}
