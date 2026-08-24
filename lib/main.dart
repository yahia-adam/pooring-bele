import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/audio_service.dart';
import 'services/content_repository.dart';
import 'services/progress_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentRepository.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(PooringBeleApp(
    content: content,
    progress: ProgressService(prefs),
  ));
}

class PooringBeleApp extends StatelessWidget {
  final AppContent content;
  final ProgressService progress;

  const PooringBeleApp({
    super.key,
    required this.content,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppContent>.value(value: content),
        ChangeNotifierProvider<ProgressService>.value(value: progress),
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
        home: Consumer<ProgressService>(
          builder: (context, progress, _) => progress.hasProfile
              ? const HomeScreen()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
