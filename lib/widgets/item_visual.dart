import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/content_repository.dart';
import '../theme.dart';

/// Visuel d'un mot : l'image du contenu si elle existe, sinon un visuel
/// de secours dessiné selon le type de catégorie (couleur, lettre, chiffre,
/// calendrier, emoji). L'app reste ainsi jouable avant même que les
/// illustrations finales soient produites.
class ItemVisual extends StatelessWidget {
  final WordItem item;
  final CategoryDef category;

  const ItemVisual({super.key, required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();

    if (item.image.isNotEmpty && content.hasAsset(item.image)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'content/${item.image}',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    switch (category.kind) {
      case CategoryKind.colors:
        return _ColorSwatch(color: item.swatchColor ?? category.color);
      case CategoryKind.letters:
        return _GlyphCard(
          upper: item.upper ?? item.label,
          lower: item.lower,
          color: category.color,
        );
      case CategoryKind.numbers:
        return _GlyphCard(upper: item.chiffre ?? item.label, color: category.color);
      case CategoryKind.calendar:
        return _CalendarCard(
          short: item.short ?? item.label,
          color: category.color,
        );
      case CategoryKind.words:
        return _EmojiCard(emoji: item.emoji ?? category.emoji);
    }
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color.lerp(color, Colors.white, .25)!, color],
              center: const Alignment(-.4, -.4),
            ),
            border: Border.all(color: Colors.black12, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlyphCard extends StatelessWidget {
  final String upper;
  final String? lower;
  final Color color;

  const _GlyphCard({required this.upper, this.lower, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                upper,
                style: AppTheme.furText(fontSize: 52, color: darken(color)),
              ),
              if (lower != null) ...[
                const SizedBox(width: 4),
                Text(
                  lower!,
                  style: AppTheme.furText(
                    fontSize: 36,
                    color: darken(color).withValues(alpha: .55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final String short;
  final Color color;

  const _CalendarCard({required this.short, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 6),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    2,
                    (_) => Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        short,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: darken(color),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiCard extends StatelessWidget {
  final String emoji;

  const _EmojiCard({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(emoji, style: const TextStyle(fontSize: 56)),
        ),
      ),
    );
  }
}
