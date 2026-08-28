import 'dart:ui';

/// Configuration globale de l'app, chargée depuis `content/config.json`.
class AppConfig {
  final String appName;
  final String tagline;
  final List<String> avatars;
  final int questionsPerLesson;
  final int coinsPerCorrect;
  final int coinsLessonBonus;
  final int threeStarPct;
  final int twoStarPct;
  final int oneStarPct;

  const AppConfig({
    required this.appName,
    required this.tagline,
    required this.avatars,
    required this.questionsPerLesson,
    required this.coinsPerCorrect,
    required this.coinsLessonBonus,
    required this.threeStarPct,
    required this.twoStarPct,
    required this.oneStarPct,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final quiz = (json['quiz'] as Map<String, dynamic>?) ?? const {};
    final thresholds =
        (quiz['starThresholds'] as Map<String, dynamic>?) ?? const {};
    return AppConfig(
      appName: json['appName'] as String? ?? 'Poor\'íŋ Belé',
      tagline: json['tagline'] as String? ?? '',
      avatars: List<String>.from(json['avatars'] as List? ?? const ['⭐']),
      questionsPerLesson: quiz['questionsPerLesson'] as int? ?? 10,
      coinsPerCorrect: quiz['coinsPerCorrect'] as int? ?? 2,
      coinsLessonBonus: quiz['coinsLessonBonus'] as int? ?? 5,
      threeStarPct: thresholds['three'] as int? ?? 90,
      twoStarPct: thresholds['two'] as int? ?? 70,
      oneStarPct: thresholds['one'] as int? ?? 50,
    );
  }

  int starsForScore(int correct, int total) {
    if (total == 0) return 0;
    final pct = correct * 100 ~/ total;
    if (pct >= threeStarPct) return 3;
    if (pct >= twoStarPct) return 2;
    if (pct >= oneStarPct) return 1;
    return 0;
  }
}

/// Façon de dessiner le visuel de secours quand l'image n'existe pas encore.
enum CategoryKind { letters, numbers, colors, calendar, words }

CategoryKind kindFromString(String? s) {
  switch (s) {
    case 'letters':
      return CategoryKind.letters;
    case 'numbers':
      return CategoryKind.numbers;
    case 'colors':
      return CategoryKind.colors;
    case 'calendar':
      return CategoryKind.calendar;
    default:
      return CategoryKind.words;
  }
}

class CategoryDef {
  final String id;
  final String title;
  final CategoryKind kind;
  final Color color;
  final String emoji;
  final String pack;

  const CategoryDef({
    required this.id,
    required this.title,
    required this.kind,
    required this.color,
    required this.emoji,
    required this.pack,
  });

  factory CategoryDef.fromJson(Map<String, dynamic> json) => CategoryDef(
        id: json['id'] as String,
        title: json['title'] as String? ?? json['id'] as String,
        kind: kindFromString(json['kind'] as String?),
        color: parseHexColor(json['color'] as String? ?? '#3FA9F5'),
        emoji: json['emoji'] as String? ?? '⭐',
        pack: json['pack'] as String,
      );
}

class LevelDef {
  final String id;
  final String title;
  final String subtitle;
  final List<CategoryDef> categories;

  const LevelDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categories,
  });

  factory LevelDef.fromJson(Map<String, dynamic> json) => LevelDef(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        categories: (json['categories'] as List)
            .map((c) => CategoryDef.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class ContentManifest {
  final String mediaBaseUrl;
  final List<LevelDef> levels;

  const ContentManifest({required this.mediaBaseUrl, required this.levels});

  factory ContentManifest.fromJson(Map<String, dynamic> json) =>
      ContentManifest(
        mediaBaseUrl: json['mediaBaseUrl'] as String? ?? '',
        levels: (json['levels'] as List)
            .map((l) => LevelDef.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

/// Un mot (ou lettre, chiffre, couleur…) d'une catégorie.
class WordItem {
  final String id;

  /// Le mot écrit en fur (à remplir dans les JSON par le référent linguistique).
  final String ecrit;
  final String? fr;
  final String? upper;
  final String? lower;
  final String? chiffre;
  final String? hex;
  final String? short;
  final String? emoji;
  final String image;
  final String audio;

  const WordItem({
    required this.id,
    required this.ecrit,
    this.fr,
    this.upper,
    this.lower,
    this.chiffre,
    this.hex,
    this.short,
    this.emoji,
    required this.image,
    required this.audio,
  });

  factory WordItem.fromJson(Map<String, dynamic> json) => WordItem(
        id: json['id'] as String,
        ecrit: json['ecrit'] as String? ?? '',
        fr: json['fr'] as String?,
        upper: json['upper'] as String?,
        lower: json['lower'] as String?,
        chiffre: json['chiffre'] as String?,
        hex: json['hex'] as String?,
        short: json['short'] as String?,
        emoji: json['emoji'] as String?,
        image: json['image'] as String? ?? '',
        audio: json['audio'] as String? ?? '',
      );

  /// Texte affiché à l'enfant : le fur en priorité, sinon un repère connu.
  String get label {
    if (ecrit.isNotEmpty) return ecrit;
    if (fr != null && fr!.isNotEmpty) return fr!;
    if (upper != null && upper!.isNotEmpty) return upper!;
    if (chiffre != null && chiffre!.isNotEmpty) return chiffre!;
    return id;
  }

  Color? get swatchColor => hex == null ? null : parseHexColor(hex!);
}

Color parseHexColor(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}
