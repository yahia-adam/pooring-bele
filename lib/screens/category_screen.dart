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
class CategoryScreen extends StatefulWidget {
  final CategoryDef category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  /// Mots déjà écoutés : la barre se remplit et la carte tapée prend la
  /// couleur de la catégorie — deux raisons, pour l'enfant, de tout
  /// explorer avant de jouer.
  final Set<String> _explored = {};

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
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
          Padding(
            padding: EdgeInsets.fromLTRB(
                dims.gapMd, dims.gapMd, dims.gapMd, dims.gapXxs),
            child: LessonProgressBar(
              current: _explored.length,
              total: items.length,
              color: color,
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
                  itemBuilder: (context, i) => _DiscoveryCard(
                    item: items[i],
                    category: category,
                    explored: _explored.contains(items[i].id),
                    onTap: () {
                      context.read<AudioService>().playItem(items[i]);
                      setState(() => _explored.add(items[i].id));
                    },
                  ),
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

/// Carte d'un mot de l'imagier : bordure sobre tant qu'il n'a pas été
/// écouté, couleur de la catégorie une fois [explored].
class _DiscoveryCard extends StatelessWidget {
  final WordItem item;
  final CategoryDef category;
  final bool explored;
  final VoidCallback onTap;

  const _DiscoveryCard({
    required this.item,
    required this.category,
    required this.explored,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    final hasAudio = context.read<AppContent>().hasLocalAudio(item);

    return TapCard(
      accent: explored ? category.color : null,
      filled: explored,
      glow: explored,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(child: ItemVisual(item: item, category: category)),
          SizedBox(height: dims.gapXxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.label.toUpperCase(),
              style: AppTheme.furText(fontSize: dims.s(15)),
              textAlign: TextAlign.center,
            ),
          ),
          if (hasAudio)
            Icon(
              Icons.volume_up_rounded,
              size: dims.iconSm,
              color: explored ? darken(category.color) : TapCard.soberBorder,
            ),
        ],
      ),
    );
  }
}
