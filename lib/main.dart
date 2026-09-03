import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_choice_screen.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/content_repository.dart';
import 'services/progress_service.dart';
import 'theme.dart';

/// Projet Supabase du classement. La clé anon/publishable est faite pour
/// être publique : les accès sont contrôlés par les policies RLS
/// (voir supabase/schema.sql), pas par le secret de cette clé.
const _supabaseUrl = 'https://sikrfrnmhofrogkxchdk.supabase.co';
const _supabaseAnonKey = 'sb_publishable_lhxqHtO0ssYmOYw7ijakng_kMw8YSaW';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentRepository.load();
  final prefs = await SharedPreferences.getInstance();
  await Supabase.initialize(
      url: _supabaseUrl, publishableKey: _supabaseAnonKey);

  final auth = AuthService();
  final progress = ProgressService(prefs, accountId: auth.currentUser?.id);

  // Session Supabase restaurée (compte déjà connecté) mais rien en local
  // pour ce compte sur cet appareil (nouvel appareil, cache effacé) : on
  // rapatrie le profil avant d'afficher quoi que ce soit, pour ne pas
  // montrer un en-tête vide.
  if (auth.isLoggedIn && progress.name.isEmpty) {
    try {
      final profile = await auth.fetchMyProfile();
      await progress.setProfile(
        name: profile.firstName,
        avatar: profile.avatarUrl ?? '',
      );
    } catch (_) {
      // Hors ligne au démarrage : l'app affichera un en-tête vide plutôt
      // que de bloquer le lancement, la synchro suivante corrigera ça.
    }
  }

  runApp(PooringBeleApp(
    content: content,
    progress: progress,
    auth: auth,
  ));
}

class PooringBeleApp extends StatelessWidget {
  final AppContent content;
  final ProgressService progress;
  final AuthService auth;

  const PooringBeleApp({
    super.key,
    required this.content,
    required this.progress,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppContent>.value(value: content),
        ChangeNotifierProvider<ProgressService>.value(value: progress),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<AudioService>(
          create: (_) => AudioService(content),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: content.config.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer2<ProgressService, AuthService>(
          builder: (context, progress, auth, _) {
            if (auth.isLoggedIn) return const HomeScreen();
            if (progress.hasProfile && progress.isGuest) {
              return const HomeScreen();
            }
            return const AuthChoiceScreen();
          },
        ),
      ),
    );
  }
}
