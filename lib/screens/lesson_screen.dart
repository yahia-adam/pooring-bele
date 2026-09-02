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
import 'result_screen.dart';

/// Une question : on entend le mot, on tape sur le bon élément parmi 4.
class Exercise {
  final WordItem target;
  final List<WordItem> choices;

  const Exercise({required this.target, required this.choices});
}

/// Une leçon : suite de questions audio → élément, générées depuis le JSON.
class LessonScreen extends StatefulWidget {
  final CategoryDef category;

  const LessonScreen({super.key, required this.category});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final List<Exercise> _exercises;
  late final AudioService _audio;
  int _index = 0;
  int _firstTryCorrect = 0;
  bool _currentMissed = false;
  bool _locked = false;

  // État des cartes de la question courante.
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
    // Coupe le son si on quitte la leçon (retour ou fin).
    _audio.stop();
    super.dispose();
  }

  List<Exercise> _generate() {
    final rng = Random();
    final content = context.read<AppContent>();
    final all = content.itemsOf(widget.category.id);

    final pool = [...all]..shuffle(rng);
    final count = min(content.config.questionsPerLesson, pool.length);

    return [
      for (var i = 0; i < count; i++)
        () {
          final target = pool[i];
          final others = all.where((w) => w.id != target.id).toList()
            ..shuffle(rng);
          return Exercise(
            target: target,
            choices: [target, ...others.take(3)]..shuffle(rng),
          );
        }(),
    ];
  }

  Exercise get _current => _exercises[_index];

  void _playCurrent() {
    context.read<AudioService>().playItem(_current.target);
  }

  void _onChoiceTap(WordItem choice) {
    if (_locked) return;
    if (choice.id == _current.target.id) {
      _onCorrect();
    } else {
      setState(() {
        _currentMissed = true;
        _wrongIds.add(choice.id);
        _shakeCounter++;
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _onCorrect() {
    setState(() {
      _locked = true;
      _correctId = _current.target.id;
      if (!_currentMissed) _firstTryCorrect++;
    });
    // Pas de re-lecture du mot ici : chaque question ne joue son audio
    // qu'une fois (au démarrage, ou via le bouton haut-parleur).
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
    final stars = config.starsForScore(_firstTryCorrect, total);
    final coins = _firstTryCorrect * config.coinsPerCorrect +
        (stars > 0 ? config.coinsLessonBonus : 0);

    final progress = context.read<ProgressService>();
    final previousStars = progress.starsFor(widget.category.id);
    await progress.recordLesson(
      categoryId: widget.category.id,
      stars: stars,
      coinsEarned: coins,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          category: widget.category,
          stars: stars,
          correct: _firstTryCorrect,
          total: total,
          coinsEarned: coins,
          newGem: stars == 3 && previousStars < 3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color;
    final progress = context.watch<ProgressService>();

    if (_exercises.isEmpty) {
      // Catégorie sans contenu : on ressort sans jouer.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: SizedBox());
    }

    final dims = context.dims;

    return Scaffold(
      backgroundColor: pastelOf(color),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
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
                  child: Text(
                    widget.category.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                dims.gapMd, dims.gapMd, dims.gapMd, dims.gapXxs),
            child: LessonProgressBar(
              current: _index + 1,
              total: _exercises.length,
              color: color,
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
                    key: ValueKey('$_index-${_current.target.id}'),
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          // La pulsation attire l'œil : « appuie ici pour
                          // réécouter le mot ».
                          child: Pulse(
                            child: BigRoundButton(
                              icon: Icons.volume_up_rounded,
                              color: color,
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
                                    item: choice,
                                    category: widget.category,
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

  ChoiceState _stateOf(WordItem choice) {
    if (_correctId == choice.id) return ChoiceState.correct;
    if (_wrongIds.contains(choice.id)) return ChoiceState.wrong;
    return ChoiceState.idle;
  }
}
