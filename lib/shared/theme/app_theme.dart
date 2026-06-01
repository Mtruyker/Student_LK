import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData build(AppShellRole role, [Brightness brightness = Brightness.light]) {
    final isDark = brightness == Brightness.dark;
    final seed = AppColors.primaryFor(role);
    
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
    );

    final colorScheme = base.colorScheme.copyWith(
      primary: seed,
      secondary: AppColors.info,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceContainerHighest: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
      outline: isDark ? AppColors.borderDark : AppColors.border,
      outlineVariant: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.6),
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      error: AppColors.danger,
    );

    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = interTextTheme.copyWith(
      displayLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.displayLarge,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.displayMedium,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.manrope(
        textStyle: interTextTheme.displaySmall,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineLarge,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineMedium,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineSmall,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.titleLarge,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.titleMedium,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: GoogleFonts.manrope(
        textStyle: interTextTheme.titleSmall,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: interTextTheme.bodyLarge?.copyWith(
        color: textPrimary,
        height: 1.45,
      ),
      bodyMedium: interTextTheme.bodyMedium?.copyWith(
        color: textPrimary,
        height: 1.45,
      ),
      bodySmall: interTextTheme.bodySmall?.copyWith(
        color: textSecondary,
        height: 1.35,
      ),
      labelLarge: interTextTheme.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: interTextTheme.labelMedium?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: interTextTheme.labelSmall?.copyWith(
        color: textSecondary,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(
        color: (isDark ? AppColors.borderDark : AppColors.border).withValues(alpha: 0.9),
        space: 24,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.danger,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: seed, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          textStyle: textTheme.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 56),
          textStyle: textTheme.titleSmall,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          minimumSize: const Size(0, 52),
          textStyle: textTheme.titleSmall,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        height: 78,
        indicatorColor: seed.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seed
                : textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? seed
                : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.9),
        indicatorColor: seed.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: seed),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: seed,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: textSecondary,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: textSecondary,
        ),
        selectedColor: seed.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Colors.white : AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
