import 'package:audioplayers/audioplayers.dart';

import '../models/content.dart';
import 'content_repository.dart';

/// Lecture audio des mots. Un seul lecteur, un seul son à la fois :
/// toute nouvelle lecture remplace la précédente, et les appels sont
/// sérialisés pour éviter tout chevauchement ou double lecture.
class AudioService {
  final AppContent content;
  final AudioPlayer _player = AudioPlayer();

  /// Chaîne des opérations du lecteur : garantit que stop/play
  /// s'exécutent toujours dans l'ordre, jamais en parallèle.
  Future<void> _queue = Future.value();

  AudioService(this.content) {
    _player.audioCache = AudioCache(prefix: '');
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _queue = _queue.then((_) => action(), onError: (_) => action());
    return _queue;
  }

  /// Joue l'audio d'un mot : d'abord l'asset embarqué (hors-ligne),
  /// sinon le CDN du manifeste. Silencieux si le média n'existe pas.
  Future<void> playItem(WordItem item) {
    if (item.audio.isEmpty) return Future.value();
    return _enqueue(() async {
      try {
        await _player.stop();
        if (content.hasAsset(item.audio)) {
          await _player.play(AssetSource('content/${item.audio}'));
        } else if (content.manifest.mediaBaseUrl.isNotEmpty) {
          await _player
              .play(UrlSource('${content.manifest.mediaBaseUrl}${item.audio}'));
        }
      } catch (_) {
        // Média manquant ou réseau indisponible : on n'interrompt pas le jeu.
      }
    });
  }

  /// Arrête la lecture en cours (changement d'écran).
  Future<void> stop() {
    return _enqueue(() async {
      try {
        await _player.stop();
      } catch (_) {}
    });
  }

  void dispose() {
    _player.dispose();
  }
}
