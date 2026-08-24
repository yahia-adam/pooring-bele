import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';

/// Fin de leçon : étoiles gagnées, pièces, rejouer ou continuer.
class ResultScreen extends StatelessWidget {
  final CategoryDef category;
  final int stars;
  final int correct;
  final int total;
  final int coinsEarned;
  final bool newGem;

  const ResultScreen({
    super.key,
    required this.category,
    required this.stars,
    required this.correct,
    required this.total,
    required this.coinsEarned,
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
    final progress = context.read<ProgressService>();
    final color = category.color;

    return Scaffold(
      backgroundColor: pastelOf(color),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 16),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.title.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: darken(color),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                bottom: middle ? 18 : 0),
                            child: Icon(
                              Icons.star_rounded,
                              size: middle ? 84 : 68,
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
                    const SizedBox(height: 10),
                    Text(
                      _message(progress.name),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$correct bonnes réponses sur $total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: .55),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _RewardChip(emoji: '🪙', label: '+$coinsEarned'),
                        if (newGem)
                          const _RewardChip(emoji: '💎', label: '+1'),
                      ],
                    ),
                    const SizedBox(height: 26),
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

class _RewardChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _RewardChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sun, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
