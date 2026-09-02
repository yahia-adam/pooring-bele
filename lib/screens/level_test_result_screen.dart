import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'level_test_screen.dart';

const _testAccent = Color(0xFFF08A3C);

/// Fin de test global : la coupe gagnée (ou pas encore), le score, les
/// pièces, et la possibilité de retenter le test.
class LevelTestResultScreen extends StatelessWidget {
  final LevelDef level;

  /// 0 = pas de coupe, 1 = bronze, 2 = argent, 3 = or.
  final int medal;
  final int correct;
  final int total;
  final int coinsEarned;
  final bool newGem;

  const LevelTestResultScreen({
    super.key,
    required this.level,
    required this.medal,
    required this.correct,
    required this.total,
    required this.coinsEarned,
    required this.newGem,
  });

  String get _trophy => switch (medal) {
        3 => '🥇',
        2 => '🥈',
        1 => '🥉',
        _ => '💪',
      };

  String _message(String name) {
    switch (medal) {
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
    final progress = context.read<ProgressService>();

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
                      '${level.title} · TEST FINAL',
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
                      child: Text(_trophy, style: TextStyle(fontSize: dims.starXl * 1.6)),
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
                      '$correct bonnes réponses sur $total',
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
                          child: RewardChip(emoji: '🪙', label: '+$coinsEarned'),
                        ),
                        if (newGem)
                          const Pop(
                            delay: Duration(milliseconds: 800),
                            child: RewardChip(emoji: '💎', label: '+1'),
                          ),
                      ],
                    ),
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
                                builder: (_) => LevelTestScreen(level: level),
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
