import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_repository.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Espace parents, protégé par une petite question de calcul.
class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  late final int _a;
  late final int _b;
  bool _unlocked = false;
  final _answerController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 3 + rng.nextInt(6);
    _b = 4 + rng.nextInt(6);
    _nameController.text = context.read<ProgressService>().name;
  }

  @override
  void dispose() {
    _answerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (int.tryParse(_answerController.text.trim()) == _a * _b) {
      setState(() => _unlocked = true);
    } else {
      _answerController.clear();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text('Mauvaise réponse, réessayez.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(6),
          child: BackBubble(iconColor: AppColors.ink),
        ),
        title: Text(
          'Espace parents',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _unlocked ? _buildSettings() : _buildGate(),
        ),
      ),
    );
  }

  Widget _buildGate() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            'Réservé aux parents',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Combien font $_a × $_b ?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
              onSubmitted: (_) => _checkAnswer(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'VALIDER',
            color: AppColors.sky,
            onTap: _checkAnswer,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final theme = Theme.of(context);
    final content = context.read<AppContent>();
    final progress = context.watch<ProgressService>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: 'Profil de l\'enfant',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final emoji in content.config.avatars)
                    Bouncy(
                      onTap: () => progress.setProfile(
                        name: _nameController.text.trim().isEmpty
                            ? progress.name
                            : _nameController.text.trim(),
                        avatar: emoji,
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: progress.avatar == emoji
                              ? AppColors.sun.withValues(alpha: .3)
                              : AppColors.sand,
                          border: Border.all(
                            color: progress.avatar == emoji
                                ? AppColors.sun
                                : Colors.black12,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      progress.setProfile(name: name, avatar: progress.avatar);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(const SnackBar(
                            content: Text('Profil mis à jour ✔')));
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Enregistrer le prénom'),
                ),
              ),
            ],
          ),
        ),
        _SectionCard(
          title: 'Progression',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⭐ ${progress.totalStars} étoiles · 💎 ${progress.gems} gemmes · 🪙 ${progress.coins} pièces',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.wrong),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tout remettre à zéro ?'),
                        content: const Text(
                            'Étoiles, gemmes et pièces seront perdues.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Réinitialiser'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await progress.resetProgress();
                    }
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Réinitialiser la progression'),
                ),
              ),
            ],
          ),
        ),
        _SectionCard(
          title: 'À propos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${content.config.appName} — apprentissage du fur (fòòr) '
                'pour les enfants, par images et par sons.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tout le vocabulaire est défini dans les fichiers JSON du '
                'dossier « content » de l\'application : mots, traductions, '
                'images et audio peuvent être complétés sans toucher au code. '
                'Aucune donnée n\'est collectée : la progression reste sur '
                'cet appareil.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: .6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
