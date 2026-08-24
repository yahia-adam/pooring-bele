import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'parents_screen.dart';

/// Carte des niveaux : barre de statut + parcours vertical des catégories.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final progress = context.watch<ProgressService>();

    return Scaffold(
      body: Column(
        children: [
          _StatusHeader(progress: progress),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    for (var i = 0; i < content.manifest.levels.length; i++)
                      _LevelSection(
                        index: i,
                        level: content.manifest.levels[i],
                        unlocked: progress.isLevelUnlocked(content, i),
                        isLast: i == content.manifest.levels.length - 1,
                      ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '🏆',
                        style: const TextStyle(fontSize: 44),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sky, AppColors.skyDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Color(0x332B3A4A), blurRadius: 10)],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sun, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    progress.avatar,
                    style: const TextStyle(fontSize: 24),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFF08A3C), thickness: 2.5, endIndent: 14)),
              Column(
                children: [
                  Text(
                    level.title.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFF08A3C),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
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
                        padding: EdgeInsets.only(top: row == 0 ? 0 : 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 210,
                                child: _CategoryTile(
                                  category: level.categories[row * 2],
                                  unlocked: unlocked,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: row * 2 + 1 < level.categories.length
                                  ? SizedBox(
                                      height: 210,
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
                width: 34,
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
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
      ],
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
                borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: unlocked ? 1 : .35,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: pastelOf(category.color, .82),
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.all(4),
                          ),
                          Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 44),
                          ),
                          if (!unlocked)
                            const Icon(Icons.lock_rounded,
                                size: 30, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  StarRow(stars: unlocked ? stars : 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
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
