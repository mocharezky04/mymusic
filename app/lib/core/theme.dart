import 'package:flutter/material.dart';

/// Palet diturunkan dari ikon aplikasi: line-art putih di atas near-black
/// (#0B0D12). Tidak ada hue selain merah error yang fungsional.
abstract final class AppColors {
  static const ink = Color(0xFF0B0D12);
  static const inkDeepest = Color(0xFF07080C);
  static const surfaceLow = Color(0xFF12141A);
  static const surface = Color(0xFF181A21);
  static const surfaceHigh = Color(0xFF1F222A);
  static const surfaceHighest = Color(0xFF272B34);

  static const text = Color(0xFFF4F5F7);
  static const textMuted = Color(0xFF9EA3AE);
  static const line = Color(0xFF5A6069);
  static const lineSoft = Color(0xFF2A2E37);

  static const danger = Color(0xFFE2685F);

  static const paper = Color(0xFFF7F8FA);
  static const paperCard = Color(0xFFFFFFFF);
  static const paperLow = Color(0xFFEFF1F4);
  static const paperSurface = Color(0xFFE7EAEE);
  static const paperHigh = Color(0xFFDEE2E7);
  static const paperHighest = Color(0xFFD3D8DE);
  static const inkText = Color(0xFF14161A);
  static const inkTextMuted = Color(0xFF5A6069);
  static const paperLine = Color(0xFF8A9099);
  static const dangerDark = Color(0xFFA8322B);
}

abstract final class AppRadius {
  static const xs = 2.0;
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
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
  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: AppColors.text,
      onPrimary: AppColors.ink,
      primaryContainer: AppColors.surfaceHigh,
      onPrimaryContainer: AppColors.text,
      secondary: AppColors.textMuted,
      onSecondary: AppColors.ink,
      surface: AppColors.ink,
      onSurface: AppColors.text,
      surfaceContainerLowest: AppColors.inkDeepest,
      surfaceContainerLow: AppColors.surfaceLow,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.line,
      outlineVariant: AppColors.lineSoft,
      error: AppColors.danger,
      onError: AppColors.ink,
    );
    return _build(scheme);
  }

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.inkText,
      onPrimary: Colors.white,
      primaryContainer: AppColors.paperHigh,
      onPrimaryContainer: AppColors.inkText,
      secondary: AppColors.inkTextMuted,
      onSecondary: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.inkText,
      surfaceContainerLowest: AppColors.paperCard,
      surfaceContainerLow: AppColors.paperLow,
      surfaceContainer: AppColors.paperSurface,
      surfaceContainerHigh: AppColors.paperHigh,
      surfaceContainerHighest: AppColors.paperHighest,
      onSurfaceVariant: AppColors.inkTextMuted,
      outline: AppColors.paperLine,
      outlineVariant: AppColors.paperHigh,
      error: AppColors.dangerDark,
      onError: Colors.white,
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
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(fontSize: 13.5, color: scheme.onSurface),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: scheme.surface),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.surfaceContainerHigh,
        height: 66,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.lineSoft,
        thumbColor: AppColors.text,
        overlayColor: Color(0x1FFFFFFF),
        trackHeight: 2,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
