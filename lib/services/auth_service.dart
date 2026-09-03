import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profil compte tel que stocké dans la table `profiles`.
class RemoteProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int points;

  const RemoteProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.points,
  });

  factory RemoteProfile.fromRow(Map<String, dynamic> row) => RemoteProfile(
        id: row['id'] as String,
        firstName: row['first_name'] as String,
        lastName: row['last_name'] as String,
        avatarUrl: row['avatar_url'] as String?,
        points: row['points'] as int? ?? 0,
      );
}

/// Compte enfant (email + mot de passe) via Supabase : inscription,
/// connexion, profil (prénom/nom/photo) et classement.
class AuthService extends ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<String> _uploadAvatar(String userId, XFile photo) async {
    final bytes = await photo.readAsBytes();
    final path = '$userId/avatar.jpg';
    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Crée le compte, envoie la photo si fournie, puis la ligne `profiles`.
  /// Retourne le profil créé.
  Future<RemoteProfile> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    XFile? photo,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null || res.session == null) {
      throw Exception(
        "Compte créé, mais une confirmation par email est demandée. "
        "Demande à un adulte de désactiver « Confirm email » dans les "
        "réglages Supabase pour une connexion simple.",
      );
    }

    String? avatarUrl;
    if (photo != null) {
      avatarUrl = await _uploadAvatar(user.id, photo);
    }

    final row = {
      'id': user.id,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'points': 0,
    };
    await _client.from('profiles').insert(row);
    notifyListeners();
    return RemoteProfile.fromRow(row);
  }

  /// Connecte puis renvoie le profil existant.
  Future<RemoteProfile> signIn({
    required String email,
    required String password,
  }) async {
    final res =
        await _client.auth.signInWithPassword(email: email, password: password);
    final user = res.user;
    if (user == null) {
      throw Exception('Connexion impossible.');
    }
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    notifyListeners();
    return RemoteProfile.fromRow(row);
  }

  /// Recharge le profil du compte actuellement connecté.
  Future<RemoteProfile> fetchMyProfile() async {
    final user = currentUser;
    if (user == null) throw Exception('Aucun compte connecté.');
    final row =
        await _client.from('profiles').select().eq('id', user.id).single();
    return RemoteProfile.fromRow(row);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  /// Met à jour ce qui est fourni (prénom, nom, et/ou une nouvelle photo) ;
  /// les champs omis restent inchangés. Retourne le profil à jour.
  Future<RemoteProfile> updateProfile({
    String? firstName,
    String? lastName,
    XFile? photo,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Aucun compte connecté.');

    final update = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'first_name': ?firstName,
      'last_name': ?lastName,
    };
    if (photo != null) {
      update['avatar_url'] = await _uploadAvatar(user.id, photo);
    }
    final row = await _client
        .from('profiles')
        .update(update)
        .eq('id', user.id)
        .select()
        .single();
    notifyListeners();
    return RemoteProfile.fromRow(row);
  }

  /// Pousse le score courant vers le classement. Échec silencieux (hors
  /// ligne, compte invité) : ne doit jamais bloquer l'enfant.
  Future<void> syncPoints(int points) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _client.from('profiles').update({
        'points': points,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      if (kDebugMode) print('syncPoints failed: $e');
    }
  }

  Future<List<RemoteProfile>> fetchLeaderboard({int limit = 50}) async {
    final rows = await _client
        .from('profiles')
        .select('id, first_name, last_name, avatar_url, points')
        .order('points', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => RemoteProfile.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
