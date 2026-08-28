# Poor'íŋ Belé — apprendre le fur en s'amusant ☀️

Application Flutter (Android · iOS · Web) d'apprentissage du vocabulaire **fur**
(fòòr) pour les enfants de 5 à 12 ans : images, sons, petits jeux, étoiles et
pièces. Voir le [cahier des charges](docs/cahier-des-charges.md).

**Tout le contenu pédagogique est dans des fichiers JSON** (`content/`) : on
peut ajouter des mots, des catégories, des images et de l'audio **sans toucher
au code**.

## Démarrer

```bash
flutter pub get
flutter run -d chrome     # web
flutter run               # appareil/émulateur Android ou iOS
flutter test              # tests (cohérence du contenu JSON)
```

## Fonctionnalités

- **Carte des niveaux** : parcours vertical, catégories en tuiles, étoiles de
  maîtrise (3 max), niveaux déverrouillés par la progression.
- **Imagier de découverte** : on explore les mots, chaque carte joue l'audio.
- **Leçons** (10 questions, générées depuis le JSON) : un seul type de jeu —
  on **entend le mot** (bouton haut-parleur pour réécouter) et on **tape sur
  l'élément correspondant** parmi 4 (lettre, chiffre, couleur, jour, mois,
  membre de la famille…).
- **Gamification** : étoiles, pièces, gemmes, avatar + prénom, messages de
  félicitations.
- **Espace parents** (protégé par un calcul) : profil, remise à zéro, à propos.
- **Hors-ligne** : tout le contenu embarqué fonctionne sans réseau ; la
  progression est stockée sur l'appareil (aucune collecte de données).

## Modifier le contenu

Voir [`content/README.md`](content/README.md). En bref :

- `content/config.json` — nom de l'app, avatars, réglages du quiz, clavier fur ;
- `content/manifest.json` — niveaux, catégories, couleurs, packs ;
- `content/categories/*.json` — les mots de chaque catégorie ;
- `content/images/<catégorie>/` et `content/audio/<catégorie>/` — déposer ici
  les médias (`.webp`, `.m4a`). **L'app les détecte automatiquement** : sans
  image elle dessine un visuel de secours (pastille de couleur, lettre,
  chiffre, mini-calendrier, emoji) ; sans audio local elle tente le CDN du
  manifeste, sinon la question reste silencieuse.

Après modification : `flutter test` vérifie la cohérence, puis rebuild.

## Publier

La version est dans `pubspec.yaml` (`version: 1.0.0+1` → nom de version +
numéro de build). Icônes : `dart run flutter_launcher_icons` (source
`assets_dev/icon.png`).

### Android (Google Play)

1. Créer une clé de signature :
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Créer `android/key.properties` et brancher la signature release dans
   `android/app/build.gradle.kts`
   (guide officiel : https://docs.flutter.dev/deployment/android — actuellement
   le build release signe avec la clé de debug, à remplacer avant publication).
3. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
4. Play Console : créer l'app (`applicationId` : `com.pooringbele.app`),
   remplir la fiche (catégorie enfants → programme « Conçu pour les familles »,
   politique de confidentialité requise), téléverser l'AAB.

### iOS (App Store)

Sur un Mac avec Xcode :

1. `open ios/Runner.xcworkspace` → régler l'équipe de signature (compte Apple
   Developer) et le bundle identifier.
2. `flutter build ipa --release` → téléverser via Transporter ou Xcode.
3. App Store Connect : fiche app, catégorie enfants (règles COPPA), captures.

### Web

```bash
flutter build web --release
```

Le dossier `build/web/` est un site statique : à déposer tel quel sur Netlify,
Vercel, Firebase Hosting, GitHub Pages ou n'importe quel serveur. Pour un
sous-chemin : `flutter build web --base-href /mon-chemin/`.

## Architecture

```
lib/
├── main.dart                  # bootstrap + providers + MaterialApp (fr)
├── theme.dart                 # palette, polices (Baloo 2 + Noto Sans pour le fur)
├── models/content.dart        # AppConfig, Manifest, Category, WordItem
├── services/
│   ├── content_repository.dart  # charge les JSON + inventaire des assets
│   ├── progress_service.dart    # profil, pièces, gemmes, étoiles (SharedPreferences)
│   └── audio_service.dart       # lecture audio (asset local, sinon CDN)
├── screens/
│   ├── onboarding_screen.dart   # avatar + prénom
│   ├── home_screen.dart         # carte des niveaux + barre de statut
│   ├── category_screen.dart     # imagier de découverte
│   ├── lesson_screen.dart       # moteur d'exercices (QCM)
│   ├── spelling_exercise.dart   # dictée avec clavier fur
│   ├── result_screen.dart       # étoiles + récompenses
│   └── parents_screen.dart      # espace parents
└── widgets/                   # composants (cartes, étoiles, boutons…)
```
