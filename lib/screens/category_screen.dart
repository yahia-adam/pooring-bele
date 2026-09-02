import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/audio_service.dart';
import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/item_visual.dart';
import 'lesson_screen.dart';

/// Mode découverte (imagier) d'une catégorie : on explore, on écoute,
/// puis on lance la leçon avec le gros bouton « Jouer ».
class CategoryScreen extends StatelessWidget {
  final CategoryDef category;

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final progress = context.watch<ProgressService>();
    final items = content.itemsOf(category.id);
    final color = category.color;
    final dims = context.dims;

    return Scaffold(
      backgroundColor: pastelOf(color),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(dims.radiusLg)),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 8),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + dims.gapXs,
              left: dims.gapSm,
              right: dims.gapSm,
              bottom: dims.gapSm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const BackBubble(),
                    Expanded(
                      child: Text(
                        category.title,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: .4,
                                ),
                      ),
                    ),
                    StatChip(emoji: '🪙', value: '${progress.coins}'),
                  ],
                ),
                SizedBox(height: dims.gapXs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StarRow(
                        stars: progress.starsFor(category.id),
                        size: dims.starMd),
                    SizedBox(width: dims.gapSm),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: dims.gapSm, vertical: dims.gapXxs),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(dims.radiusLg),
                      ),
                      child: Text(
                        '${items.length} mots',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                      dims.gapMd, dims.gapMd, dims.gapMd, dims.s(110)),
                  gridDelegate:
                      SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: dims.s(150),
                    mainAxisSpacing: dims.gapSm,
                    crossAxisSpacing: dims.gapSm,
                    childAspectRatio: .82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _DiscoveryCard(item: items[i], category: category),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: PrimaryButton(
        label: 'JOUER',
        icon: Icons.play_arrow_rounded,
        color: darken(color, .08),
        onTap: items.length < 4
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonScreen(category: category),
                  ),
                ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final WordItem item;
  final CategoryDef category;

  const _DiscoveryCard({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final hasAudio = content.hasLocalAudio(item);

    return Bouncy(
      onTap: () => context.read<AudioService>().playItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: category.color.withValues(alpha: .5), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(child: ItemVisual(item: item, category: category)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label.toUpperCase(),
                style: AppTheme.furText(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasAudio)
              Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: category.color.withValues(alpha: .7),
              ),
          ],
        ),
      ),
    );
  }
}
