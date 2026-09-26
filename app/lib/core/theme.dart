import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF0A0A12);
  static const inkSoft = Color(0xFF14141F);
  static const violet = Color(0xFF7C5CFF);
  static const violetBright = Color(0xFF9D7BFF);
  static const cyan = Color(0xFF22D3EE);
  static const pinkCoral = Color(0xFFFF5C8A);
  static const paper = Color(0xFFF4F7FD);
  static const muted = Color(0xFF9A94C4);
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppTheme {
  static const _darkSecondary = Color(0xFF22D3EE);
  static const _lightSecondary = Color(0xFF0E7490);

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: AppColors.violetBright,
      onPrimary: const Color(0xFF0F0A1F),
      primaryContainer: const Color(0xFF2A1F5C),
      onPrimaryContainer: const Color(0xFFDCD2FF),
      secondary: _darkSecondary,
      onSecondary: const Color(0xFF06172B),
      surface: AppColors.ink,
      onSurface: const Color(0xFFF2F0FF),
      surfaceContainerLowest: const Color(0xFF06060C),
      surfaceContainerLow: const Color(0xFF0E0E18),
      surfaceContainer: const Color(0xFF14141F),
      surfaceContainerHigh: const Color(0xFF1C1C2A),
      surfaceContainerHighest: AppColors.inkSoft,
      onSurfaceVariant: AppColors.muted,
      outline: const Color(0xFF6B6B85),
      error: AppColors.pinkCoral,
    );
    return _build(scheme);
  }

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.violet,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6DCFF),
      onPrimaryContainer: const Color(0xFF1F1255),
      secondary: _lightSecondary,
      onSecondary: Colors.white,
      surface: AppColors.paper,
      onSurface: const Color(0xFF14132B),
      surfaceContainerLowest: const Color(0xFFFCFDFF),
      surfaceContainerLow: const Color(0xFFF1EEFF),
      surfaceContainer: const Color(0xFFE8E2FF),
      surfaceContainerHigh: const Color(0xFFDFD7F8),
      surfaceContainerHighest: const Color(0xFFD3C8F0),
      onSurfaceVariant: const Color(0xFF575073),
      outline: const Color(0xFF8C85A8),
      error: const Color(0xFFB8324D),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.15,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(fontSize: 13.5, color: scheme.onSurface),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: scheme.onSurfaceVariant,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        foregroundColor: scheme.primary,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: scheme.surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        height: 66,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.16),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 3,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.24),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
