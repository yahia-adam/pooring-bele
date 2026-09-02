import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'level_test_screen.dart';
import 'parents_screen.dart';

/// Carte des niveaux : barre de statut + parcours vertical des catégories.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final progress = context.watch<ProgressService>();
    final dims = context.dims;

    return Scaffold(
      body: Column(
        children: [
          _StatusHeader(progress: progress),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppDims.maxContentWidth),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      dims.gapMd, dims.gapXs, dims.gapMd, dims.gapXl),
                  children: [
                    for (var i = 0; i < content.manifest.levels.length; i++)
                      _LevelSection(
                        index: i,
                        level: content.manifest.levels[i],
                        unlocked: progress.isLevelUnlocked(content, i),
                        isLast: i == content.manifest.levels.length - 1,
                      ),
                    SizedBox(height: dims.gapSm),
                    Center(
                      child: Text(
                        '🏆',
                        style: TextStyle(fontSize: dims.emojiLg),
                      ),
                    ),
                    Center(
                      child: Text(
                        'D\'autres niveaux arrivent bientôt !',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.ink.withValues(alpha: .5),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final ProgressService progress;

  const _StatusHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sky, AppColors.skyDark],
        ),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(dims.radiusXl)),
        boxShadow: const [BoxShadow(color: Color(0x332B3A4A), blurRadius: 10)],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + dims.gapXs,
        left: dims.gapMd,
        right: dims.gapMd,
        bottom: dims.gapSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: dims.gapXs,
              runSpacing: dims.gapXxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatChip(emoji: '⭐', value: '${progress.totalStars}'),
                StatChip(emoji: '💎', value: '${progress.gems}'),
                StatChip(emoji: '🪙', value: '${progress.coins}'),
              ],
            ),
          ),
          Bouncy(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParentsScreen()),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: dims.headerAvatar,
                  height: dims.headerAvatar,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sun, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    progress.avatar,
                    style: TextStyle(fontSize: dims.emojiMd),
                  ),
                ),
                Text(
                  progress.name.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final int index;
  final LevelDef level;
  final bool unlocked;
  final bool isLast;

  const _LevelSection({
    required this.index,
    required this.level,
    required this.unlocked,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: dims.gapMd),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFF08A3C), thickness: 2.5, endIndent: 14)),
              Column(
                children: [
                  Text(
                    level.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFF08A3C),
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      letterSpacing: .6,
                    ),
                  ),
                  if (level.subtitle.isNotEmpty)
                    Text(
                      level.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: .55),
                      ),
                    ),
                ],
              ),
              const Expanded(child: Divider(color: Color(0xFFF08A3C), thickness: 2.5, indent: 14)),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var row = 0;
                        row * 2 < level.categories.length;
                        row++)
                      Padding(
                        padding:
                            EdgeInsets.only(top: row == 0 ? 0 : dims.gapMd),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: dims.categoryTileHeight,
                                child: _CategoryTile(
                                  category: level.categories[row * 2],
                                  unlocked: unlocked,
                                ),
                              ),
                            ),
                            SizedBox(width: dims.gapMd),
                            Expanded(
                              child: row * 2 + 1 < level.categories.length
                                  ? SizedBox(
                                      height: dims.categoryTileHeight,
                                      child: _CategoryTile(
                                        category:
                                            level.categories[row * 2 + 1],
                                        unlocked: unlocked,
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: dims.s(34),
                child: Column(
                  children: [
                    Container(
                      width: dims.s(30),
                      height: dims.s(30),
                      decoration: BoxDecoration(
                        color: unlocked ? Colors.white : AppColors.starGrey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF08A3C),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: unlocked
                          ? Text(
                              '${index + 1}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFFF08A3C),
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : const Icon(Icons.lock_rounded,
                              size: 16, color: Colors.white),
                    ),
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.starGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (unlocked)
          Padding(
            padding: EdgeInsets.only(top: dims.gapMd),
            child: _LevelTestTile(level: level),
          ),
      ],
    );
  }
}

/// Carte du test global de fin de niveau : verrouillée tant que toutes les
/// catégories du niveau n'ont pas au moins une étoile, sinon elle ouvre le
/// test dont le score décide de la coupe (bronze/argent/or) et débloque le
/// niveau suivant.
class _LevelTestTile extends StatelessWidget {
  final LevelDef level;

  const _LevelTestTile({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final progress = context.watch<ProgressService>();
    final testUnlocked = progress.isTestUnlocked(level);
    final medal = progress.medalFor(level.id);
    final trophy = switch (medal) {
      3 => '🥇',
      2 => '🥈',
      1 => '🥉',
      _ => '🏆',
    };
    final subtitle = !testUnlocked
        ? 'Termine toutes les catégories pour le débloquer'
        : medal > 0
            ? 'Coupe obtenue · rejoue pour l\'améliorer'
            : 'Toutes les catégories réunies, à toi de jouer !';

    return Bouncy(
      onTap: () {
        if (!testUnlocked) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text(
                  'Gagne des étoiles dans toutes les catégories pour débloquer le test ! 🔒'),
            ));
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LevelTestScreen(level: level)),
        );
      },
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(horizontal: dims.gapMd, vertical: dims.gapSm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(dims.radiusMd),
          border: Border.all(
            color: medal == 3 ? AppColors.sun : const Color(0xFFF08A3C),
            width: medal == 3 ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Opacity(
              opacity: testUnlocked ? 1 : .35,
              child: Text(trophy, style: TextStyle(fontSize: dims.emojiLg)),
            ),
            SizedBox(width: dims.gapSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test final',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: .55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              testUnlocked ? Icons.chevron_right_rounded : Icons.lock_rounded,
              color: AppColors.ink.withValues(alpha: .55),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryDef category;
  final bool unlocked;

  const _CategoryTile({required this.category, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final progress = context.watch<ProgressService>();
    final stars = progress.starsFor(category.id);
    final content = context.read<AppContent>();
    final itemCount = content.itemsOf(category.id).length;

    return Bouncy(
      onTap: () {
        if (!unlocked) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content:
                  Text('Gagne des étoiles au niveau précédent pour ouvrir ! 🔒'),
            ));
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CategoryScreen(category: category)),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(dims.radiusMd),
                border: Border.all(
                  color: stars == 3 ? AppColors.sun : const Color(0xFFE3E8EE),
                  width: stars == 3 ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.all(dims.gapXs),
              child: Column(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: unlocked ? 1 : .35,
                      // Un vrai cercle (AspectRatio 1) et un emoji dimensionné
                      // par rapport au cercle : plus de débordement sur les
                      // petits écrans.
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: EdgeInsets.all(dims.gapXxs),
                            decoration: BoxDecoration(
                              color: pastelOf(category.color, .82),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: .58,
                                  heightFactor: .58,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Text(category.emoji),
                                  ),
                                ),
                                if (!unlocked)
                                  Icon(Icons.lock_rounded,
                                      size: dims.s(30),
                                      color: AppColors.ink),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: dims.gapXxs),
                  StarRow(stars: unlocked ? stars : 0),
                ],
              ),
            ),
          ),
          SizedBox(height: dims.gapXxs),
          Text(
            category.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: .2,
            ),
          ),
          Text(
            '$itemCount mots',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.ink.withValues(alpha: .45),
            ),
          ),
        ],
      ),
    );
  }
}
