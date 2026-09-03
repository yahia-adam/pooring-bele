import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'leaderboard_popup.dart';
import 'lesson_screen.dart';

/// Fin de leçon : étoiles gagnées, pièces, rejouer ou continuer.
class ResultScreen extends StatelessWidget {
  final CategoryDef category;
  final int stars;
  final int correct;
  final int total;
  final int coinsEarned;

  /// Points de classement gagnés dans cette leçon : ils alimentent
  /// l'animation de montée dans le pop-up du classement.
  final int pointsEarned;
  final bool newGem;

  const ResultScreen({
    super.key,
    required this.category,
    required this.stars,
    required this.correct,
    required this.total,
    required this.coinsEarned,
    required this.pointsEarned,
    required this.newGem,
  });

  String _message(String name) {
    switch (stars) {
      case 3:
        return 'Incroyable $name ! 🎉';
      case 2:
        return 'Bravo $name !';
      case 1:
        return 'Bien joué $name !';
      default:
        return 'Continue $name, tu vas y arriver !';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final progress = context.read<ProgressService>();
    final color = category.color;

    return Scaffold(
      backgroundColor: pastelOf(color),
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
                      category.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: darken(color),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: .4,
                      ),
                    ),
                    SizedBox(height: dims.gapMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(3, (i) {
                        final earned = i < stars;
                        final middle = i == 1;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration:
                              Duration(milliseconds: 500 + i * 320),
                          curve: Curves.elasticOut,
                          builder: (context, t, child) =>
                              Transform.scale(scale: t, child: child),
                          child: Padding(
                            padding: EdgeInsets.only(
                                bottom: middle ? dims.gapSm : 0),
                            child: Icon(
                              Icons.star_rounded,
                              size: middle ? dims.starXl : dims.starLg,
                              color: earned
                                  ? AppColors.starGold
                                  : AppColors.starGrey,
                              shadows: earned
                                  ? const [
                                      Shadow(
                                        color: Color(0x55B8860B),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
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
                          child:
                              RewardChip(emoji: '🪙', label: '+$coinsEarned'),
                        ),
                        if (newGem)
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
                          coinsEarned: coinsEarned,
                          pointsEarned: pointsEarned,
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
                                    LessonScreen(category: category),
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
                            // Retour direct à la liste des catégories : la
                            // leçon (et la page catégorie qui l'a lancée)
                            // sont derrière, on ne veut pas s'y arrêter.
                            onTap: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
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
