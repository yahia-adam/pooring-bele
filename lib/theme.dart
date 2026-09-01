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

  /// Style pour le texte en fur : Noto Sans (embarqué) couvre Ŋ, Ɨ, Ʉ, A̠
  /// et les tons combinés. Police embarquée plutôt que google_fonts car ce
  /// texte vient de JSON chargés au runtime — le sous-ensemble de glyphes
  /// que google_fonts calcule à la compilation ne les voit pas.
  static TextStyle furText({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      TextStyle(
        fontFamily: 'NotoSansFur',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}

/// Dimensions responsives centralisées.
///
/// Toutes les tailles de l'app partent d'une maquette de 390 pt de large
/// (iPhone 12) et sont multipliées par un facteur d'échelle dérivé du côté
/// court de l'écran, borné pour rester lisible du petit téléphone à la
/// tablette. Règle du projet : aucun écran n'écrit de taille en dur, tout
/// passe par `context.dims`.
class AppDims {
  /// Largeur de référence de la maquette.
  static const _baseWidth = 390.0;

  /// Largeur maximale du contenu centré (tablettes, web).
  static const maxContentWidth = 560.0;

  final double scale;

  const AppDims(this.scale);

  factory AppDims.of(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return AppDims((shortest / _baseWidth).clamp(.8, 1.25));
  }

  /// Met une valeur de la maquette à l'échelle de l'écran courant.
  double s(double base) => base * scale;

  // Espacements.
  double get gapXxs => s(4);
  double get gapXs => s(8);
  double get gapSm => s(12);
  double get gapMd => s(16);
  double get gapLg => s(22);
  double get gapXl => s(28);

  // Rayons d'angle.
  double get radiusSm => s(14);
  double get radiusMd => s(18);
  double get radiusLg => s(22);
  double get radiusXl => s(28);

  // Icônes et emojis.
  double get iconSm => s(16);
  double get iconMd => s(24);
  double get emojiSm => s(17);
  double get emojiMd => s(24);
  double get emojiLg => s(44);

  // Étoiles de maîtrise.
  double get starSm => s(22);
  double get starMd => s(26);
  double get starLg => s(54);
  double get starXl => s(68);

  // Composants.
  double get headerAvatar => s(46);
  double get backBubble => s(42);
  double get logo => s(96);
  double get speakerButton => s(84);
  double get progressBarHeight => s(18);
  double get categoryTileHeight => s(205);
  double get textFieldRadius => s(18);
}

extension AppDimsX on BuildContext {
  AppDims get dims => AppDims.of(this);
}

/// Teinte pastel dérivée de la couleur d'une catégorie (fond d'écran leçon).
Color pastelOf(Color color, [double amount = .88]) =>
    Color.lerp(color, Colors.white, amount)!;

Color darken(Color color, [double amount = .18]) =>
    Color.lerp(color, Colors.black, amount)!;
