import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';
import '../services/content_repository.dart';

/// Progression locale de l'enfant (profil, pièces, gemmes, étoiles).
class ProgressService extends ChangeNotifier {
  static const _kName = 'profile.name';
  static const _kAvatar = 'profile.avatar';
  static const _kCoins = 'wallet.coins';
  static const _kGems = 'wallet.gems';
  static const _kStars = 'progress.stars';
  static const _kLevelTests = 'progress.levelTests';

  final SharedPreferences _prefs;

  String _name = '';
  String _avatar = '⭐';
  int _coins = 0;
  int _gems = 0;
  Map<String, int> _stars = {};

  /// Meilleure médaille obtenue au test global de chaque niveau
  /// (0 = pas encore réussi, 1 = bronze, 2 = argent, 3 = or).
  Map<String, int> _levelTests = {};

  ProgressService(this._prefs) {
    _name = _prefs.getString(_kName) ?? '';
    _avatar = _prefs.getString(_kAvatar) ?? '⭐';
    _coins = _prefs.getInt(_kCoins) ?? 0;
    _gems = _prefs.getInt(_kGems) ?? 0;
    final raw = _prefs.getString(_kStars);
    if (raw != null) {
      _stars = Map<String, int>.from(json.decode(raw) as Map);
    }
    final rawTests = _prefs.getString(_kLevelTests);
    if (rawTests != null) {
      _levelTests = Map<String, int>.from(json.decode(rawTests) as Map);
    }
  }

  bool get hasProfile => _name.isNotEmpty;
  String get name => _name;
  String get avatar => _avatar;
  int get coins => _coins;
  int get gems => _gems;

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
      _prefs.setString(_kName, name),
      _prefs.setString(_kAvatar, avatar),
    ]);
  }

  Future<void> addCoins(int amount) {
    _coins += amount;
    notifyListeners();
    return _prefs.setInt(_kCoins, _coins);
  }

  /// Retourne `false` si l'enfant n'a pas assez de pièces.
  Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    notifyListeners();
    await _prefs.setInt(_kCoins, _coins);
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
        await _prefs.setInt(_kGems, _gems);
      }
      await _prefs.setString(_kStars, json.encode(_stars));
    }
    _coins += coinsEarned;
    await _prefs.setInt(_kCoins, _coins);
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
        await _prefs.setInt(_kGems, _gems);
      }
      await _prefs.setString(_kLevelTests, json.encode(_levelTests));
    }
    _coins += coinsEarned;
    await _prefs.setInt(_kCoins, _coins);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _coins = 0;
    _gems = 0;
    _stars = {};
    _levelTests = {};
    notifyListeners();
    await Future.wait([
      _prefs.remove(_kCoins),
      _prefs.remove(_kGems),
      _prefs.remove(_kStars),
      _prefs.remove(_kLevelTests),
    ]);
  }
}
