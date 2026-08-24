import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette inspirée des maquettes : ciel, soleil, sable.
class AppColors {
  static const sky = Color(0xFF3FA9F5);
  static const skyDark = Color(0xFF1E88D2);
  static const sand = Color(0xFFF7F9FC);
  static const sun = Color(0xFFFFC107);
  static const starGold = Color(0xFFFFC94D);
  static const starGrey = Color(0xFFD5DBE1);
  static const coin = Color(0xFFF5A623);
  static const gem = Color(0xFF8E6FF7);
  static const correct = Color(0xFF34C759);
  static const wrong = Color(0xFFFF5252);
  static const ink = Color(0xFF2B3A4A);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sky,
        surface: AppColors.sand,
      ),
      scaffoldBackgroundColor: AppColors.sand,
    );

    final textTheme = GoogleFonts.baloo2TextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    );
  }

  /// Style pour le texte en fur : Noto Sans couvre Ŋ, Ɨ, Ʉ, A̠ et les tons.
  static TextStyle furText({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.notoSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}

/// Teinte pastel dérivée de la couleur d'une catégorie (fond d'écran leçon).
Color pastelOf(Color color, [double amount = .88]) =>
    Color.lerp(color, Colors.white, amount)!;

Color darken(Color color, [double amount = .18]) =>
    Color.lerp(color, Colors.black, amount)!;
