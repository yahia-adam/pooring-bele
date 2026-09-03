import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

/// Inscription compte enfant : prénom, nom, photo, email, mot de passe —
/// le minimum pour rejoindre le classement.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _photo;
  Uint8List? _photoBytes;
  bool _loading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    setState(() {
      _photo = photo;
      _photoBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final progress = context.read<ProgressService>();
    try {
      final profile = await auth.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        photo: _photo,
      );
      await progress.switchAccount(profile.id);
      await progress.setProfile(
        name: firstName,
        avatar: profile.avatarUrl ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? "Impossible de créer le compte." : message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;

    return AuthScaffold(
      emoji: '🎈',
      title: 'Crée ton profil de joueur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Bouncy(
                  onTap: _pickPhoto,
                  child: Container(
                    width: dims.s(96),
                    height: dims.s(96),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sand,
                      border: Border.all(color: AppColors.sun, width: 3),
                      image: _photoBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_photoBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _photoBytes == null
                        ? Icon(Icons.add_a_photo_rounded,
                            size: dims.s(32),
                            color: AppColors.ink.withValues(alpha: .45))
                        : null,
                  ),
                ),
                SizedBox(height: dims.gapXs),
                Text(
                  'Photo de profil',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.ink.withValues(alpha: .55)),
                ),
              ],
            ),
          ),
          SizedBox(height: dims.gapLg),
          PlayfulField(
            controller: _firstNameController,
            label: 'Prénom',
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: dims.gapSm),
          PlayfulField(
            controller: _lastNameController,
            label: 'Nom',
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: dims.gapSm),
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
                  label: 'CRÉER MON COMPTE',
                  icon: Icons.rocket_launch_rounded,
                  color: AppColors.correct,
                  onTap: _submit,
                ),
        ],
      ),
    );
  }
}
