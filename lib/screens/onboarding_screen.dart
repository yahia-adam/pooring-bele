import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Création du profil enfant : avatar + prénom.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _avatar;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final theme = Theme.of(context);
    final canStart = _avatar != null && _nameController.text.trim().isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sky, Color(0xFF7DC9FA), AppColors.sand],
            stops: [0, .45, .8],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('☀️', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 4),
                    Text(
                      content.config.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
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
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 16),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choisis ton avatar',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final emoji in content.config.avatars)
                                Bouncy(
                                  onTap: () =>
                                      setState(() => _avatar = emoji),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: _avatar == emoji
                                          ? AppColors.sun
                                              .withValues(alpha: .25)
                                          : AppColors.sand,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _avatar == emoji
                                            ? AppColors.sun
                                            : Colors.black12,
                                        width: _avatar == emoji ? 3 : 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Ton prénom',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 20,
                            onChanged: (_) => setState(() {}),
                            style: theme.textTheme.titleLarge,
                            decoration: InputDecoration(
                              hintText: 'Ex. Amina',
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.sand,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: PrimaryButton(
                              label: "C'EST PARTI !",
                              icon: Icons.rocket_launch_rounded,
                              color: AppColors.correct,
                              onTap: canStart
                                  ? () => context
                                      .read<ProgressService>()
                                      .setProfile(
                                        name: _nameController.text.trim(),
                                        avatar: _avatar!,
                                      )
                                  : null,
                            ),
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
