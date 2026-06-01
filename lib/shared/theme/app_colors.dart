import 'package:flutter/material.dart';

enum AppShellRole {
  student,
  teacher,
  admin,
}

class AppColors {
  const AppColors._();

  // --- Light Theme Colors ---
  static const Color background = Color(0xFFF6F3EE);
  static const Color surface = Color(0xFFFFFDFC);
  static const Color surfaceMuted = Color(0xFFF2EEE7);
  static const Color textPrimary = Color(0xFF18211B);
  static const Color textSecondary = Color(0xFF5F6B63);
  static const Color border = Color(0xFFE6E1D8);

  // --- Dark Theme Colors ---
  static const Color backgroundDark = Color(0xFF121412);
  static const Color surfaceDark = Color(0xFF1C1E1C);
  static const Color surfaceMutedDark = Color(0xFF262826);
  static const Color textPrimaryDark = Color(0xFFE6EAE6);
  static const Color textSecondaryDark = Color(0xFFAAB2AA);
  static const Color borderDark = Color(0xFF323632);

  // --- Shared Semantics ---
  static const Color warning = Color(0xFFC96A2B);
  static const Color success = Color(0xFF2D8A63);
  static const Color info = Color(0xFF2E6FD8);
  static const Color danger = Color(0xFFBB5A3E);

  // --- Role Primaries ---
  static const Color studentPrimary = Color(0xFF1F6A52);
  static const Color teacherPrimary = Color(0xFF2D5FB6);
  static const Color adminPrimary = Color(0xFF375C8E);

  static Color primaryFor(AppShellRole role) {
    switch (role) {
      case AppShellRole.teacher:
        return teacherPrimary;
      case AppShellRole.admin:
        return adminPrimary;
      case AppShellRole.student:
        return studentPrimary;
    }
  }

  static LinearGradient heroGradientFor(AppShellRole role, [Brightness brightness = Brightness.light]) {
    final isDark = brightness == Brightness.dark;

    switch (role) {
      case AppShellRole.teacher:
        return LinearGradient(
          colors: <Color>[
            isDark ? const Color(0xFF152C52) : const Color(0xFF234A88),
            isDark ? const Color(0xFF234475) : const Color(0xFF3D74C7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppShellRole.admin:
        return LinearGradient(
          colors: <Color>[
            isDark ? const Color(0xFF19263B) : const Color(0xFF2B4166),
            isDark ? const Color(0xFF2D4464) : const Color(0xFF4F77B0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppShellRole.student:
        return LinearGradient(
          colors: <Color>[
            isDark ? const Color(0xFF0D2C22) : const Color(0xFF164A3A),
            isDark ? const Color(0xFF1C4B3B) : const Color(0xFF2F7E63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
