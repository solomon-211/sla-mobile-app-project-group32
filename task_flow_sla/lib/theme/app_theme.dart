import 'package:flutter/material.dart';

/// Every colour used in the app lives here so the screens stay consistent.
class AppColors {
  static const primary = Color(0xFF0B7A66);
  static const background = Color(0xFFF1F5F4);
  static const surface = Colors.white;
  static const textDark = Color(0xFF16211E);
  static const textMuted = Color(0xFF6B7774);
  static const border = Color(0xFFDDE5E2);

  // SLA status colours (solid versions, used for charts and icons).
  static const onTrack = Color(0xFF1E8E5A);
  static const atRisk = Color(0xFFDE9A1A);
  static const overdue = Color(0xFFD63B30);
  static const completed = Color(0xFF3C5BA9);

  static const priorityMedium = Color(0xFFB97800);

  /// Background / foreground pairs for member avatars.
  static const avatarPalette = <(Color, Color)>[
    (Color(0xFFD7EBE5), Color(0xFF0B5C4D)),
    (Color(0xFFE2E3F3), Color(0xFF2F3A8F)),
    (Color(0xFFFBE7CD), Color(0xFF8A4B00)),
    (Color(0xFFF1DDF0), Color(0xFF8A2D84)),
    (Color(0xFFD9E8FA), Color(0xFF1D4E89)),
    (Color(0xFFFADADD), Color(0xFF9B2335)),
  ];
}

/// Every text style used in the app, so sizes and weights stay consistent.
/// Use `.copyWith(color: ...)` when a style needs a status or brand colour.
class AppText {
  /// App name on the sign-in screen.
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  /// Main heading of a screen, e.g. the task title, and big numbers.
  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  /// Section titles such as "Needs attention" or "Members (4)".
  static const section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  /// Titles inside cards and list tiles.
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const body = TextStyle(fontSize: 14, color: AppColors.textDark);

  static const bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const bodyMuted = TextStyle(fontSize: 14, color: AppColors.textMuted);

  /// Form field labels.
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  /// Small secondary text: dates, roles, counts.
  static const caption = TextStyle(fontSize: 12, color: AppColors.textMuted);

  /// Text inside status pills and badges.
  static const pill = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
}

class AppTheme {
  static const double radius = 12;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.overdue,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 1.5),
        errorBorder: inputBorder(AppColors.overdue),
        focusedErrorBorder: inputBorder(AppColors.overdue, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.primary),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
