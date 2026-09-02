import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Rebond au tap, façon jouet : s'écrase vite à l'appui puis revient
/// avec un ressort élastique au relâchement.
///
/// L'animation est pilotée par un [AnimationController] joué en entier dès
/// que [onTap] se déclenche, plutôt que par les timings bruts de
/// `onTapDown`/`onTapUp`. Sur un appui très bref (un tapotement d'enfant),
/// ces deux évènements pouvaient arriver si près l'un de l'autre qu'aucune
/// frame intermédiaire n'était jamais peinte : l'animation ne se voyait
/// alors que sur les appuis tenus assez longtemps (~1s). En rejouant la
/// séquence complète à chaque tap, le rebond est toujours visible, même
/// pour un tap instantané.
class Bouncy extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Bouncy({super.key, required this.child, this.onTap});

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      weight: 25,
      tween: Tween<double>(begin: 1, end: .9)
          .chain(CurveTween(curve: Curves.easeOut)),
    ),
    TweenSequenceItem(
      weight: 75,
      tween: Tween<double>(begin: .9, end: 1)
          .chain(CurveTween(curve: Curves.elasticOut)),
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              // Rejoue depuis le début même si un tap précédent est encore
              // en cours d'animation (appuis rapides et répétés).
              _controller.forward(from: 0);
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Apparition élastique (pop de jouet) : bonnes réponses, récompenses…
class Pop extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const Pop({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay == Duration.zero
            ? 0
            : delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: Curves.elasticOut,
      ),
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}

/// Pulsation douce et continue (respiration) : attire l'œil de l'enfant
/// sur le bouton à presser, sans être agressive.
class Pulse extends StatefulWidget {
  final Widget child;

  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: .97, end: 1.05).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
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

  /// Taille de base d'une étoile ; par défaut `dims.starSm`.
  final double? size;

  const StarRow({super.key, required this.stars, this.size});

  @override
  Widget build(BuildContext context) {
    final starSize = size ?? context.dims.starSm;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final earned = i < stars;
        final middle = i == 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: middle ? starSize * .22 : 0,
            left: i == 0 ? 0 : 1,
          ),
          child: Icon(
            Icons.star_rounded,
            size: middle ? starSize * 1.15 : starSize,
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
    final dims = context.dims;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dims.gapSm,
        vertical: dims.gapXxs + 2,
      ),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(dims.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: dims.emojiSm)),
          SizedBox(width: dims.gapXxs + 2),
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
    final dims = context.dims;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: dims.progressBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(dims.radiusSm),
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
                    width: math.max(
                        dims.progressBarHeight, constraints.maxWidth * fraction),
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          BorderRadius.circular(dims.radiusSm * .6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(width: dims.gapSm),
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

  /// Diamètre ; par défaut `dims.speakerButton`.
  final double? size;
  final VoidCallback onTap;

  const BigRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = size ?? context.dims.speakerButton;
    return Bouncy(
      onTap: onTap,
      child: Container(
        width: diameter,
        height: diameter,
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
        child: Icon(icon, color: Colors.white, size: diameter * .5),
      ),
    );
  }
}

/// Gros bouton d'action principal, arrondi et coloré. Son contenu se
/// réduit automatiquement si la place manque (petits écrans, gros texte
/// système) au lieu de déborder.
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
    final dims = context.dims;
    final enabled = onTap != null;
    return Bouncy(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : .45,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dims.gapMd,
            vertical: dims.gapSm + 2,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(dims.radiusLg),
            boxShadow: [
              BoxShadow(
                color: darken(color, .28).withValues(alpha: .55),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: dims.iconMd),
                  SizedBox(width: dims.gapXs),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
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
    final dims = context.dims;
    return Bouncy(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: dims.backBubble,
        height: dims.backBubble,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor ?? Colors.white,
          size: dims.backBubble * .48,
        ),
      ),
    );
  }
}

/// État d'une carte de choix dans un quiz (leçon ou test global).
enum ChoiceState { idle, correct, wrong }

/// Carte cliquable d'un choix de quiz : cadre animé selon [state]
/// (idle / bonne réponse / mauvaise réponse), utilisée aussi bien pour les
/// leçons par catégorie que pour le test global de fin de niveau.
class ChoiceFrame extends StatelessWidget {
  final ChoiceState state;
  final int shakeCounter;
  final VoidCallback onTap;
  final Widget child;

  const ChoiceFrame({
    super.key,
    required this.state,
    required this.shakeCounter,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    final borderColor = switch (state) {
      ChoiceState.correct => AppColors.correct,
      ChoiceState.wrong => AppColors.wrong,
      ChoiceState.idle => const Color(0xFFE3E8EE),
    };

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dims.radiusMd),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          if (state == ChoiceState.correct)
            const BoxShadow(color: Color(0x5534C759), blurRadius: 14)
          else
            const BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
        ],
      ),
      padding: EdgeInsets.all(dims.gapXs),
      child: child,
    );

    Widget wrapped = switch (state) {
      // Bonne réponse : la carte rebondit joyeusement et un confetti
      // surgit dans le coin.
      ChoiceState.correct => TweenAnimationBuilder<double>(
          tween: Tween(begin: .85, end: 1),
          duration: const Duration(milliseconds: 550),
          curve: Curves.elasticOut,
          builder: (context, t, child) =>
              Transform.scale(scale: t, child: child),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              Positioned(
                top: -dims.gapXs,
                right: -dims.gapXxs,
                child: Pop(
                  delay: const Duration(milliseconds: 120),
                  child: Text('🎉',
                      style: TextStyle(fontSize: dims.emojiMd * 1.3)),
                ),
              ),
            ],
          ),
        ),
      // Mauvaise réponse : secousse puis la carte s'estompe pour
      // guider l'enfant vers les choix restants.
      ChoiceState.wrong => Shake(
          trigger: shakeCounter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: .55,
            child: card,
          ),
        ),
      ChoiceState.idle => card,
    };

    return Bouncy(onTap: onTap, child: wrapped);
  }
}

/// Pastille de récompense (pièces, gemmes…) affichée en fin de leçon ou
/// de test global.
class RewardChip extends StatelessWidget {
  final String emoji;
  final String label;

  const RewardChip({super.key, required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dims.gapMd,
        vertical: dims.gapXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(dims.radiusLg),
        border: Border.all(color: AppColors.sun, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: dims.emojiSm + 4)),
          SizedBox(width: dims.gapXxs),
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
