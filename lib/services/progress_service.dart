import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/content_repository.dart';

/// Progression locale de l'enfant (profil, pièces, gemmes, étoiles).
class ProgressService extends ChangeNotifier {
  static const _kName = 'profile.name';
  static const _kAvatar = 'profile.avatar';
  static const _kCoins = 'wallet.coins';
  static const _kGems = 'wallet.gems';
  static const _kStars = 'progress.stars';

  final SharedPreferences _prefs;

  String _name = '';
  String _avatar = '⭐';
  int _coins = 0;
  int _gems = 0;
  Map<String, int> _stars = {};

  ProgressService(this._prefs) {
    _name = _prefs.getString(_kName) ?? '';
    _avatar = _prefs.getString(_kAvatar) ?? '⭐';
    _coins = _prefs.getInt(_kCoins) ?? 0;
    _gems = _prefs.getInt(_kGems) ?? 0;
    final raw = _prefs.getString(_kStars);
    if (raw != null) {
      _stars = Map<String, int>.from(json.decode(raw) as Map);
    }
  }

  bool get hasProfile => _name.isNotEmpty;
  String get name => _name;
  String get avatar => _avatar;
  int get coins => _coins;
  int get gems => _gems;

  int starsFor(String categoryId) => _stars[categoryId] ?? 0;

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  /// Le niveau `index` est ouvert si le précédent totalise au moins
  /// une étoile par catégorie (en moyenne).
  bool isLevelUnlocked(AppContent content, int index) {
    if (index <= 0) return true;
    final previous = content.manifest.levels[index - 1];
    final earned =
        previous.categories.fold(0, (sum, c) => sum + starsFor(c.id));
    return earned >= previous.categories.length;
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

  Future<void> resetProgress() async {
    _coins = 0;
    _gems = 0;
    _stars = {};
    notifyListeners();
    await Future.wait([
      _prefs.remove(_kCoins),
      _prefs.remove(_kGems),
      _prefs.remove(_kStars),
    ]);
  }
}
