import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Premier lancement : l'enfant donne juste son prénom, l'avatar est
/// tiré au sort (modifiable ensuite dans l'espace parents).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final avatars = context.read<AppContent>().config.avatars;
    final avatar = avatars.isEmpty
        ? '⭐'
        : avatars[Random().nextInt(avatars.length)];
    context.read<ProgressService>().setProfile(name: name, avatar: avatar);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final theme = Theme.of(context);
    final dims = context.dims;
    final canStart = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sky, Color(0xFF7DC9FA), AppColors.sand],
            stops: [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            // Le scroll n'est qu'un filet de sécurité (clavier ouvert,
            // très petit écran) : le contenu tient sans scroller.
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: dims.gapLg,
                vertical: dims.gapSm,
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppDims.maxContentWidth),
                child: Column(
                  children: [
                    Pop(
                      child: Container(
                        padding: EdgeInsets.all(dims.gapXxs),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(dims.radiusXl),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(dims.radiusLg),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: dims.logo,
                            height: dims.logo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: dims.gapSm),
                    Text(
                      content.config.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(color: Color(0x552B3A4A), blurRadius: 8),
                        ],
                      ),
                    ),
                    Text(
                      content.config.tagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: dims.gapLg),
                    Container(
                      padding: EdgeInsets.all(dims.gapLg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(dims.radiusXl),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 16),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Comment tu t\'appelles ?',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: dims.gapMd),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textAlign: TextAlign.center,
                            maxLength: 20,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _start(),
                            style: theme.textTheme.titleLarge,
                            decoration: InputDecoration(
                              hintText: 'Ton prénom',
                              hintStyle: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.ink.withValues(alpha: .35),
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.sand,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(dims.textFieldRadius),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: dims.gapMd,
                                vertical: dims.gapSm,
                              ),
                            ),
                          ),
                          SizedBox(height: dims.gapMd),
                          PrimaryButton(
                            label: "C'EST PARTI !",
                            icon: Icons.rocket_launch_rounded,
                            color: AppColors.correct,
                            onTap: canStart ? _start : null,
                          ),
                        ],
                      ),
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
