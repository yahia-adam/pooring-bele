import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'signup_screen.dart';

/// Premier écran : créer un compte (classement), se connecter, ou jouer
/// sans compte (progression locale uniquement, comme avant).
class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<AppContent>();
    final theme = Theme.of(context);
    final dims = context.dims;

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
                          borderRadius: BorderRadius.circular(dims.radiusXl),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(dims.radiusLg),
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
                            'Prêt à jouer ? 🚀',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: dims.gapMd),
                          PrimaryButton(
                            label: 'CRÉER UN COMPTE',
                            icon: Icons.rocket_launch_rounded,
                            color: AppColors.correct,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            ),
                          ),
                          SizedBox(height: dims.gapSm),
                          PrimaryButton(
                            label: 'SE CONNECTER',
                            icon: Icons.login_rounded,
                            color: AppColors.sky,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                          ),
                          SizedBox(height: dims.gapMd),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const OnboardingScreen()),
                            ),
                            child: Text(
                              'Jouer sans compte',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.ink.withValues(alpha: .55),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
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
