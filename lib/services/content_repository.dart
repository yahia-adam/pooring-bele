import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/content.dart';

/// Tout le contenu de l'app, chargé une fois au démarrage depuis `content/`.
class AppContent {
  final AppConfig config;
  final ContentManifest manifest;
  final Map<String, List<WordItem>> packs;
  final Set<String> assetKeys;

  const AppContent({
    required this.config,
    required this.manifest,
    required this.packs,
    required this.assetKeys,
  });

  List<WordItem> itemsOf(String categoryId) => packs[categoryId] ?? const [];

  /// `rel` est un chemin relatif du manifeste, ex. `images/couleurs/rouge.webp`.
  bool hasAsset(String rel) => assetKeys.contains('content/$rel');

  bool hasAudio(WordItem item) =>
      item.audio.isNotEmpty &&
      (hasAsset(item.audio) || manifest.mediaBaseUrl.isNotEmpty);

  /// L'audio embarqué (hors-ligne) existe-t-il vraiment ?
  bool hasLocalAudio(WordItem item) =>
      item.audio.isNotEmpty && hasAsset(item.audio);

  CategoryDef? categoryById(String id) {
    for (final level in manifest.levels) {
      for (final cat in level.categories) {
        if (cat.id == id) return cat;
      }
    }
    return null;
  }
}

class ContentRepository {
  static Future<AppContent> load() async {
    final configJson = await rootBundle.loadString('content/config.json');
    final manifestJson = await rootBundle.loadString('content/manifest.json');

    final config =
        AppConfig.fromJson(json.decode(configJson) as Map<String, dynamic>);
    final manifest = ContentManifest.fromJson(
        json.decode(manifestJson) as Map<String, dynamic>);

    final packs = <String, List<WordItem>>{};
    for (final level in manifest.levels) {
      for (final cat in level.categories) {
        final packJson = await rootBundle.loadString('content/${cat.pack}');
        final data = json.decode(packJson) as Map<String, dynamic>;
        packs[cat.id] = (data['items'] as List)
            .map((i) => WordItem.fromJson(i as Map<String, dynamic>))
            .toList();
      }
    }

    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = assetManifest.listAssets().toSet();

    return AppContent(
      config: config,
      manifest: manifest,
      packs: packs,
      assetKeys: keys,
    );
  }
}
