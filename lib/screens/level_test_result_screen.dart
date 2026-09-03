import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'leaderboard_popup.dart';
import 'level_test_screen.dart';

const _testAccent = Color(0xFFF08A3C);

/// Fin de test global : la coupe gagnée (ou pas encore), le score, les
/// pièces, et la possibilité de retenter le test.
///
/// Pour un compte, le classement s'ouvre ensuite tout seul en pop-up : les
/// pièces récoltées s'accumulent dans le compteur, puis l'enfant est
/// propulsé jusqu'à son nouveau rang.
class LevelTestResultScreen extends StatefulWidget {
  final LevelDef level;

  /// 0 = pas de coupe, 1 = bronze, 2 = argent, 3 = or.
  final int medal;
  final int correct;
  final int total;
  final int coinsEarned;

  /// Points de classement gagnés au test : ils alimentent l'animation de
  /// montée dans le pop-up du classement.
  final int pointsEarned;
  final bool newGem;

  const LevelTestResultScreen({
    super.key,
    required this.level,
    required this.medal,
    required this.correct,
    required this.total,
    required this.coinsEarned,
    required this.pointsEarned,
    required this.newGem,
  });

  @override
  State<LevelTestResultScreen> createState() => _LevelTestResultScreenState();
}

class _LevelTestResultScreenState extends State<LevelTestResultScreen> {
  @override
  void initState() {
    super.initState();
    // Le temps que la coupe rebondisse et que les pièces s'affichent, puis
    // le classement prend le relais — comme à la fin d'un niveau de jeu.
    if (!context.read<ProgressService>().isGuest) {
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        showLeaderboardPopup(
          context,
          coinsEarned: widget.coinsEarned,
          pointsEarned: widget.pointsEarned,
        );
      });
    }
  }

  String get _trophy => switch (widget.medal) {
        3 => '🥇',
        2 => '🥈',
        1 => '🥉',
        _ => '💪',
      };

  String _message(String name) {
    switch (widget.medal) {
      case 3:
        return 'Coupe en or, $name ! Incroyable ! 🎉';
      case 2:
        return 'Coupe en argent, bravo $name !';
      case 1:
        return 'Coupe en bronze, bien joué $name !';
      default:
        return 'Presque, $name ! Retente le test pour décrocher une coupe.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final progress = context.watch<ProgressService>();

    return Scaffold(
      backgroundColor: pastelOf(_testAccent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(dims.gapLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dims.gapMd,
                  vertical: dims.gapLg,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(dims.radiusXl),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 16),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.level.title} · TEST FINAL',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: darken(_testAccent),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: .4,
                      ),
                    ),
                    SizedBox(height: dims.gapMd),
                    Pop(
                      duration: const Duration(milliseconds: 650),
                      child: Text(_trophy,
                          style: TextStyle(fontSize: dims.starXl * 1.6)),
                    ),
                    SizedBox(height: dims.gapXs),
                    Text(
                      _message(progress.name),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: dims.gapXxs),
                    Text(
                      '${widget.correct} bonnes réponses sur ${widget.total}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: .55),
                      ),
                    ),
                    SizedBox(height: dims.gapMd),
                    Wrap(
                      spacing: dims.gapXs,
                      alignment: WrapAlignment.center,
                      children: [
                        Pop(
                          delay: const Duration(milliseconds: 600),
                          child: RewardChip(
                              emoji: '🪙', label: '+${widget.coinsEarned}'),
                        ),
                        if (widget.newGem)
                          const Pop(
                            delay: Duration(milliseconds: 800),
                            child: RewardChip(emoji: '💎', label: '+1'),
                          ),
                      ],
                    ),
                    if (!progress.isGuest) ...[
                      SizedBox(height: dims.gapMd),
                      Pop(
                        delay: const Duration(milliseconds: 900),
                        child: LeaderboardButton(
                          coinsEarned: widget.coinsEarned,
                          pointsEarned: widget.pointsEarned,
                        ),
                      ),
                    ],
                    SizedBox(height: dims.gapLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'REJOUER',
                            icon: Icons.replay_rounded,
                            color: const Color(0xFF90A4AE),
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LevelTestScreen(level: widget.level),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: 'SUPER !',
                            icon: Icons.check_rounded,
                            color: AppColors.correct,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
