import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pooring_bele/screens/leaderboard_popup.dart';
import 'package:pooring_bele/services/auth_service.dart';
import 'package:pooring_bele/services/progress_service.dart';
import 'package:pooring_bele/theme.dart';

/// Compte connecté simulé : redéfinit ce que le pop-up utilise, sans jamais
/// toucher au client Supabase (absent en test).
class _FakeAuth extends AuthService {
  final List<RemoteProfile> entries;

  _FakeAuth(this.entries);

  @override
  User? get currentUser => User(
        id: 'me',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

  @override
  Future<List<RemoteProfile>> fetchLeaderboard({int limit = 50}) async =>
      [...entries];
}

RemoteProfile _profile(String id, int points) => RemoteProfile(
      id: id,
      firstName: 'Enfant $id',
      lastName: '',
      avatarUrl: '🐬',
      points: points,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProgressService> makeProgress({int coins = 0}) async {
    SharedPreferences.setMockInitialValues({
      'me.profile.name': 'Zoé',
      'me.wallet.coins': coins,
      // 12 étoiles = 12 points de classement.
      'me.progress.stars': '{"couleurs":3,"chiffres":3,"lettres":3,"jours":3}',
    });
    final prefs = await SharedPreferences.getInstance();
    return ProgressService(prefs, accountId: 'me');
  }

  /// Écran de téléphone : c'est là que la place manque, pas sur la surface
  /// de test par défaut (800×600).
  void phoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget host(AuthService auth, ProgressService progress) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<ProgressService>.value(value: progress),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

  testWidgets('le pop-up propulse l\'enfant de son ancien rang au nouveau',
      (tester) async {
    phoneScreen(tester);
    // L'enfant a 12 points : devant lui il ne reste que les deux premiers,
    // il double donc trois joueurs (rang 6 → rang 3).
    final auth = _FakeAuth([
      _profile('a', 40),
      _profile('b', 22),
      _profile('c', 11),
      _profile('d', 10),
      _profile('e', 9),
      // Score encore périmé côté serveur : le pop-up doit utiliser le
      // score local (12 points) et reclasser.
      RemoteProfile(
          id: 'me', firstName: 'Zoé', lastName: '', avatarUrl: '🐬', points: 2),
    ]);
    final progress = await makeProgress(coins: 30);

    await tester.pumpWidget(host(auth, progress));
    final context = tester.element(find.byType(SizedBox).first);
    showLeaderboardPopup(context, coinsEarned: 12, pointsEarned: 10);

    await tester.pump(); // ouverture de la route
    await tester.pump(const Duration(milliseconds: 500)); // transition
    await tester.pump(); // chargement du classement (Future déjà résolu)
    await tester.pump();

    expect(find.text('CLASSEMENT'), findsOneWidget);
    expect(find.text('Zoé'), findsOneWidget);

    // Pendant le vol des pièces, le compteur part du solde d'avant (18)
    // et grimpe jusqu'au solde courant (30).
    expect(find.text('18'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600)); // pièces
    expect(find.text('30'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400)); // propulsion
    await tester.pumpAndSettle();

    // Nouveau rang : 3ᵉ, avec les 12 points locaux.
    expect(find.text('🥉'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('sans compte, le pop-up invite à en créer un', (tester) async {
    phoneScreen(tester);
    SharedPreferences.setMockInitialValues({'guest.profile.name': 'Zoé'});
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressService(prefs);
    final auth = _FakeAuth(const []);

    await tester.pumpWidget(host(auth, progress));
    showLeaderboardPopup(tester.element(find.byType(SizedBox).first));
    await tester.pumpAndSettle();

    expect(find.text('CRÉER UN COMPTE'), findsOneWidget);
  });
}
