import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';
import '../services/content_repository.dart';

/// Progression locale de l'enfant (profil, pièces, gemmes, étoiles).
///
/// Les clés sont préfixées par un « namespace » : celui de l'invité, ou
/// l'id du compte connecté. Ça isole complètement la progression de deux
/// enfants qui utilisent le même appareil avec des comptes différents —
/// sans ça, se déconnecter puis se reconnecter avec un autre compte
/// affichait (et synchronisait vers le classement !) la progression du
/// compte précédent.
class ProgressService extends ChangeNotifier {
  static const _guestNamespace = 'guest';

  static const _kName = 'profile.name';
  static const _kAvatar = 'profile.avatar';
  static const _kCoins = 'wallet.coins';
  static const _kGems = 'wallet.gems';
  static const _kStars = 'progress.stars';
  static const _kLevelTests = 'progress.levelTests';

  final SharedPreferences _prefs;
  String _namespace;

  String _name = '';
  String _avatar = '⭐';
  int _coins = 0;
  int _gems = 0;
  Map<String, int> _stars = {};

  /// Meilleure médaille obtenue au test global de chaque niveau
  /// (0 = pas encore réussi, 1 = bronze, 2 = argent, 3 = or).
  Map<String, int> _levelTests = {};

  /// [accountId] : id du compte Supabase déjà connecté au démarrage
  /// (session restaurée), ou `null` pour démarrer sur la progression
  /// invité.
  ProgressService(this._prefs, {String? accountId})
      : _namespace = accountId ?? _guestNamespace {
    _load();
  }

  String _key(String base) => '$_namespace.$base';

  void _load() {
    _name = _prefs.getString(_key(_kName)) ?? '';
    _avatar = _prefs.getString(_key(_kAvatar)) ?? '⭐';
    _coins = _prefs.getInt(_key(_kCoins)) ?? 0;
    _gems = _prefs.getInt(_key(_kGems)) ?? 0;
    final raw = _prefs.getString(_key(_kStars));
    _stars = raw != null ? Map<String, int>.from(json.decode(raw) as Map) : {};
    final rawTests = _prefs.getString(_key(_kLevelTests));
    _levelTests = rawTests != null
        ? Map<String, int>.from(json.decode(rawTests) as Map)
        : {};
  }

  /// Bascule la progression locale affichée sur un autre compte (ou sur
  /// l'invité si [accountId] est `null`), ex. après connexion/déconnexion.
  Future<void> switchAccount(String? accountId) async {
    _namespace = accountId ?? _guestNamespace;
    _load();
    notifyListeners();
  }

  bool get hasProfile => _name.isNotEmpty;
  String get name => _name;
  String get avatar => _avatar;
  int get coins => _coins;
  int get gems => _gems;

  /// `true` = pas de compte, progression uniquement locale (namespace
  /// invité).
  bool get isGuest => _namespace == _guestNamespace;

  /// Score utilisé pour le classement en ligne : les étoiles de leçon
  /// comptent chacune 1 point, une médaille de test de niveau en vaut 5
  /// (bronze=1 à or=3), pour valoriser davantage un test réussi.
  int get leaderboardPoints =>
      totalStars + _levelTests.values.fold(0, (a, b) => a + b) * 5;

  int starsFor(String categoryId) => _stars[categoryId] ?? 0;

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  /// Médaille du test global d'un niveau : 0 = pas encore réussi,
  /// 1 = bronze, 2 = argent, 3 = or.
  int medalFor(String levelId) => _levelTests[levelId] ?? 0;

  /// Le test global d'un niveau se débloque une fois que chaque catégorie
  /// du niveau a au moins une étoile.
  bool isTestUnlocked(LevelDef level) =>
      level.categories.every((c) => starsFor(c.id) > 0);

  /// Le niveau `index` est ouvert quand le test global du niveau précédent
  /// a été réussi (au moins la médaille de bronze).
  bool isLevelUnlocked(AppContent content, int index) {
    if (index <= 0) return true;
    final previous = content.manifest.levels[index - 1];
    return medalFor(previous.id) > 0;
  }

  Future<void> setProfile({required String name, required String avatar}) {
    _name = name;
    _avatar = avatar;
    notifyListeners();
    return Future.wait([
      _prefs.setString(_key(_kName), name),
      _prefs.setString(_key(_kAvatar), avatar),
    ]);
  }

  Future<void> addCoins(int amount) {
    _coins += amount;
    notifyListeners();
    return _prefs.setInt(_key(_kCoins), _coins);
  }

  /// Retourne `false` si l'enfant n'a pas assez de pièces.
  Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    notifyListeners();
    await _prefs.setInt(_key(_kCoins), _coins);
    return true;
  }

  /// Enregistre la fin d'une leçon. Les étoiles ne baissent jamais ;
  /// une catégorie passée à 3 étoiles rapporte une gemme.
  Future<void> recordLesson({
    required String categoryId,
    required int stars,
    required int coinsEarned,
  }) async {
    final previous = starsFor(categoryId);
    if (stars > previous) {
      _stars[categoryId] = stars;
      if (stars == 3) {
        _gems += 1;
        await _prefs.setInt(_key(_kGems), _gems);
      }
      await _prefs.setString(_key(_kStars), json.encode(_stars));
    }
    _coins += coinsEarned;
    await _prefs.setInt(_key(_kCoins), _coins);
    notifyListeners();
  }

  /// Enregistre le résultat du test global d'un niveau. La médaille ne
  /// baisse jamais ; une coupe d'or rapporte une gemme, comme une catégorie
  /// à 3 étoiles.
  Future<void> recordLevelTest({
    required String levelId,
    required int medal,
    required int coinsEarned,
  }) async {
    final previous = medalFor(levelId);
    if (medal > previous) {
      _levelTests[levelId] = medal;
      if (medal == 3) {
        _gems += 1;
        await _prefs.setInt(_key(_kGems), _gems);
      }
      await _prefs.setString(_key(_kLevelTests), json.encode(_levelTests));
    }
    _coins += coinsEarned;
    await _prefs.setInt(_key(_kCoins), _coins);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _coins = 0;
    _gems = 0;
    _stars = {};
    _levelTests = {};
    notifyListeners();
    await Future.wait([
      _prefs.remove(_key(_kCoins)),
      _prefs.remove(_key(_kGems)),
      _prefs.remove(_key(_kStars)),
      _prefs.remove(_key(_kLevelTests)),
    ]);
  }
}
