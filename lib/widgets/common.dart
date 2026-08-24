import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Petit rebond au tap, façon jouet.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .93 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Secoue son enfant quand [trigger] change (mauvaise réponse).
class Shake extends StatelessWidget {
  final int trigger;
  final Widget child;

  const Shake({super.key, required this.trigger, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) {
        final dx = math.sin(t * math.pi * 5) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}

/// Les trois étoiles de maîtrise, celle du centre légèrement surélevée.
class StarRow extends StatelessWidget {
  final int stars;
  final double size;

  const StarRow({super.key, required this.stars, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final earned = i < stars;
        final middle = i == 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: middle ? size * .22 : 0,
            left: i == 0 ? 0 : 1,
          ),
          child: Icon(
            Icons.star_rounded,
            size: middle ? size * 1.15 : size,
            color: earned ? AppColors.starGold : AppColors.starGrey,
            shadows: earned
                ? const [Shadow(color: Color(0x33B8860B), blurRadius: 4)]
                : null,
          ),
        );
      }),
    );
  }
}

/// Pastille de la barre de statut (étoiles, gemmes, pièces).
class StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color? background;

  const StatChip({
    super.key,
    required this.emoji,
    required this.value,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression x/n des leçons.
class LessonProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color color;

  const LessonProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 4),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fraction = total == 0 ? 0.0 : current / total;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: math.max(18, constraints.maxWidth * fraction),
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$current/$total',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: darken(color), fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Gros bouton rond (haut-parleur…) avec ombre portée.
class BigRoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const BigRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: darken(color, .25).withValues(alpha: .45),
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * .5),
      ),
    );
  }
}

/// Gros bouton d'action principal, arrondi et coloré.
class PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Bouncy(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : .45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: darken(color, .28).withValues(alpha: .55),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton retour rond et blanc utilisé sur les en-têtes colorés.
class BackBubble extends StatelessWidget {
  final Color? iconColor;

  const BackBubble({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor ?? Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
