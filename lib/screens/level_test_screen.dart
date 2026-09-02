import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/audio_service.dart';
import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/item_visual.dart';
import 'level_test_result_screen.dart';

/// Couleur d'accent du test final, reprise des séparateurs de niveau sur
/// l'écran d'accueil : identifie visuellement le test comme une étape à
/// part, distincte des catégories qu'il regroupe.
const _testAccent = Color(0xFFF08A3C);

/// Un mot du test, associé à la catégorie dont il provient (nécessaire
/// pour son rendu : couleur, type de visuel de secours…) puisqu'un même
/// test mélange plusieurs catégories.
class _LeveledItem {
  final WordItem item;
  final CategoryDef category;

  const _LeveledItem({required this.item, required this.category});
}

class _TestExercise {
  final _LeveledItem target;
  final List<_LeveledItem> choices;

  const _TestExercise({required this.target, required this.choices});
}

/// Test global de fin de niveau : des questions piochées dans toutes les
/// catégories du niveau, pour décrocher la coupe (bronze, argent, or) qui
/// débloque le niveau suivant.
class LevelTestScreen extends StatefulWidget {
  final LevelDef level;

  const LevelTestScreen({super.key, required this.level});

  @override
  State<LevelTestScreen> createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends State<LevelTestScreen> {
  late final List<_TestExercise> _exercises;
  late final AudioService _audio;
  int _index = 0;
  int _firstTryCorrect = 0;
  bool _currentMissed = false;
  bool _locked = false;

  String? _correctId;
  final Set<String> _wrongIds = {};
  int _shakeCounter = 0;

  AppContent get _content => context.read<AppContent>();

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioService>();
    _exercises = _generate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrent());
  }

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  List<_TestExercise> _generate() {
    final rng = Random();
    final content = context.read<AppContent>();

    // Toutes les catégories du niveau, mélangées en un seul lot.
    final all = <_LeveledItem>[
      for (final cat in widget.level.categories)
        for (final item in content.itemsOf(cat.id))
          _LeveledItem(item: item, category: cat),
    ];

    final targets = [...all]..shuffle(rng);
    // Au moins 4 questions par catégorie pour couvrir tout le niveau,
    // sans dépasser ce qui est disponible.
    final count =
        min(widget.level.categories.length * 4, targets.length);

    return [
      for (var i = 0; i < count; i++)
        () {
          final target = targets[i];
          // Les mauvaises réponses viennent de la même catégorie que la
          // cible : le test reste discriminant, pas juste "devine le type".
          final sameCategory = all
              .where((w) =>
                  w.category.id == target.category.id &&
                  w.item.id != target.item.id)
              .toList()
            ..shuffle(rng);
          return _TestExercise(
            target: target,
            choices: [target, ...sameCategory.take(3)]..shuffle(rng),
          );
        }(),
    ];
  }

  _TestExercise get _current => _exercises[_index];

  void _playCurrent() {
    context.read<AudioService>().playItem(_current.target.item);
  }

  void _onChoiceTap(_LeveledItem choice) {
    if (_locked) return;
    if (choice.item.id == _current.target.item.id) {
      _onCorrect();
    } else {
      setState(() {
        _currentMissed = true;
        _wrongIds.add(choice.item.id);
        _shakeCounter++;
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _onCorrect() {
    setState(() {
      _locked = true;
      _correctId = _current.target.item.id;
      if (!_currentMissed) _firstTryCorrect++;
    });
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 900), _next);
  }

  void _next() {
    if (!mounted) return;
    if (_index + 1 >= _exercises.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _locked = false;
      _currentMissed = false;
      _correctId = null;
      _wrongIds.clear();
    });
    _playCurrent();
  }

  Future<void> _finish() async {
    final config = _content.config;
    final total = _exercises.length;
    final medal = config.starsForScore(_firstTryCorrect, total);
    final coins = _firstTryCorrect * config.coinsPerCorrect +
        (medal > 0 ? config.coinsLessonBonus : 0);

    final progress = context.read<ProgressService>();
    final previousMedal = progress.medalFor(widget.level.id);
    await progress.recordLevelTest(
      levelId: widget.level.id,
      medal: medal,
      coinsEarned: coins,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelTestResultScreen(
          level: widget.level,
          medal: medal,
          correct: _firstTryCorrect,
          total: total,
          coinsEarned: coins,
          newGem: medal == 3 && previousMedal < 3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();

    if (_exercises.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: SizedBox());
    }

    final dims = context.dims;

    return Scaffold(
      backgroundColor: pastelOf(_testAccent),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _testAccent,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(dims.radiusLg)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + dims.gapXs,
              left: dims.gapSm,
              right: dims.gapSm,
              bottom: dims.gapSm,
            ),
            child: Row(
              children: [
                const BackBubble(),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'TEST FINAL',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: 1,
                            ),
                      ),
                      Text(
                        widget.level.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.white.withValues(alpha: .85)),
                      ),
                    ],
                  ),
                ),
                StatChip(emoji: '🪙', value: '${progress.coins}'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                dims.gapMd, dims.gapMd, dims.gapMd, dims.gapXxs),
            child: LessonProgressBar(
              current: _index + 1,
              total: _exercises.length,
              color: _testAccent,
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppDims.maxContentWidth),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey('$_index-${_current.target.item.id}'),
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Pulse(
                            child: BigRoundButton(
                              icon: Icons.volume_up_rounded,
                              color: _testAccent,
                              onTap: _playCurrent,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              dims.gapMd, 0, dims.gapMd, dims.gapMd),
                          child: GridView.count(
                            crossAxisCount: 2,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: dims.gapSm,
                            crossAxisSpacing: dims.gapSm,
                            childAspectRatio: 1.15,
                            children: [
                              for (final choice in _current.choices)
                                ChoiceFrame(
                                  state: _stateOf(choice),
                                  shakeCounter: _shakeCounter,
                                  onTap: () => _onChoiceTap(choice),
                                  child: ItemVisual(
                                    item: choice.item,
                                    category: choice.category,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ChoiceState _stateOf(_LeveledItem choice) {
    if (_correctId == choice.item.id) return ChoiceState.correct;
    if (_wrongIds.contains(choice.item.id)) return ChoiceState.wrong;
    return ChoiceState.idle;
  }
}
