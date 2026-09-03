import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

/// Connexion à un compte existant (email + mot de passe).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final progress = context.read<ProgressService>();
    try {
      final profile = await auth.signIn(
        email: email,
        password: password,
      );
      await progress.switchAccount(profile.id);
      await progress.setProfile(
        name: profile.firstName,
        avatar: profile.avatarUrl ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text('Email ou mot de passe incorrect.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;

    return AuthScaffold(
      emoji: '👋',
      title: 'Content de te revoir !',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlayfulField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: dims.gapSm),
          PlayfulField(
            controller: _passwordController,
            label: 'Mot de passe',
            obscureText: true,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: dims.gapLg),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(
                  label: 'SE CONNECTER',
                  icon: Icons.login_rounded,
                  color: AppColors.sky,
                  onTap: _submit,
                ),
        ],
      ),
    );
  }
}
