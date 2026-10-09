import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every colour used in the app lives here so the screens stay consistent.
/// Names follow the design handoff tokens.
class AppColors {
  // Light screens
  static const ground = Color(0xFFE6E8E7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F2F2);
  static const ink = Color(0xFF2B2E2D);
  static const textMuted = Color(0xFF535856);
  static const textBody = Color(0xFF3F4341);
  static const iconMuted = Color(0xFF5F6462);
  static const hint = Color(0xFF6E7371);
  static const barEmpty = Color(0xFFDADDDC);
  static const dotMuted = Color(0xFFC4C8C6);

  // Dark screens (dashboard) and dark cards
  static const inkDeep = Color(0xFF222524);
  static const darkCard = Color(0xFF2E3231);
  static const darkCardAlt = Color(0xFF3A3E3D);
  static const darkBorder = Color(0xFF3B403E);
  static const darkNav = Color(0xFF353938);
  static const darkNavBorder = Color(0xFF434846);
  static const darkTick = Color(0xFF474C4A);

  /// Light text and light cards placed on dark backgrounds.
  static const paper = Color(0xFFF5F6F6);
  static const textMutedDark = Color(0xFFA7ACAA);
  static const textSoftDark = Color(0xFFCDD1CF);

  // Accent
  static const moss = Color(0xFF6F8F5E);
  static const mossLight = Color(0xFF8FAA7F);
  static const mossDeep = Color(0xFF56734A);
  static const mossText = Color(0xFF3E5534);
  static const onMoss = Color(0xFF121A0D);

  // Status
  static const amber = Color(0xFFD9A441);
  static const amberBg = Color(0xFFF1E2C2);
  static const amberText = Color(0xFF5C3A00);
  static const amberOnDark = Color(0xFFE3BF73);
  static const coral = Color(0xFFD9785F);
  static const onCoral = Color(0xFF2A0C04);
  static const coralText = Color(0xFFE59C88);
  static const coralBg = Color(0xFFF2D9D1);
  static const coralDeep = Color(0xFF9A2A10);
  static const error = Color(0xFFB3361A);
  static const doneBg = Color(0xFFE6E8E7);
  static const doneText = Color(0xFF2E3230);
  static const doneDot = Color(0xFF9DA2A0);

  /// Background / foreground pairs for member avatars.
  static const avatarPalette = <(Color, Color)>[
    (moss, onMoss),
    (ink, paper),
    (ground, ink),
    (dotMuted, ink),
    (mossLight, onMoss),
    (amberBg, amberText),
  ];
}

/// Text styles. Sora is used for screen titles and big numbers, Manrope for
/// everything else.
///
/// Google Fonts loads one file per weight, so always pass the weight here
/// instead of changing it later with `copyWith(fontWeight: ...)`.
class AppText {
  static TextStyle sora(
    double size, {
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: height == null ? null : height / size,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle manrope(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height == null ? null : height / size,
      letterSpacing: letterSpacing,
    );
  }

  /// "Tasks", "Team Members", "Welcome back".
  static TextStyle screenTitle({Color color = AppColors.ink}) =>
      sora(34, color: color, height: 40, letterSpacing: -1.2);

  static TextStyle body({Color color = AppColors.ink}) =>
      manrope(15, color: color, height: 22);

  static TextStyle bodyMuted() =>
      manrope(15, color: AppColors.textMuted, height: 22);

  /// Field labels and small headings.
  static TextStyle label({Color color = AppColors.ink}) =>
      manrope(13, weight: FontWeight.w800, color: color);

  /// Small secondary text: dates, roles, counts.
  static TextStyle caption({Color color = AppColors.textMuted}) =>
      manrope(12, weight: FontWeight.w700, color: color);

  /// Section headings such as "Needs attention".
  static TextStyle section({Color color = AppColors.ink}) =>
      manrope(18, weight: FontWeight.w800, color: color);

  /// Titles inside cards and list rows.
  static TextStyle cardTitle({Color color = AppColors.ink}) =>
      manrope(16, weight: FontWeight.w800, color: color);

  static TextStyle button({Color color = AppColors.paper}) =>
      manrope(16, weight: FontWeight.w800, color: color);

  /// Text inside status pills and badges.
  static TextStyle pill({Color color = AppColors.ink}) =>
      manrope(12, weight: FontWeight.w800, color: color);
}

class AppTheme {
  /// Input corner radius.
  static const double radius = 20;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.moss).copyWith(
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.moss,
      onSecondary: AppColors.onMoss,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.error,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: color == Colors.transparent
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    const stadium = StadiumBorder();
    final baseText = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ground,
      textTheme: GoogleFonts.manropeTextTheme(baseText)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ground,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.manrope(16, weight: FontWeight.w800),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      // Inputs: white, 58px tall, no border until focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        hintStyle: AppText.manrope(15, color: AppColors.hint),
        labelStyle: AppText.manrope(15, color: AppColors.textMuted),
        errorStyle: AppText.manrope(
          13,
          weight: FontWeight.w700,
          color: AppColors.error,
        ),
        counterStyle: AppText.caption(),
        prefixIconColor: AppColors.iconMuted,
        suffixIconColor: AppColors.ink,
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(AppColors.ink),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: stadium,
          textStyle: AppText.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: stadium,
          textStyle: AppText.manrope(15, weight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          minimumSize: const Size(64, 48),
          shape: stadium,
          textStyle: AppText.manrope(15, weight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(44, 44),
          shape: stadium,
          textStyle: AppText.manrope(14, weight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.moss,
        foregroundColor: AppColors.ink,
        shape: CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        titleTextStyle: AppText.sora(22),
        contentTextStyle: AppText.manrope(14, color: AppColors.textMuted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        textStyle: AppText.manrope(14, weight: FontWeight.w700),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ground,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.manrope(
          14,
          weight: FontWeight.w600,
          color: AppColors.paper,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
