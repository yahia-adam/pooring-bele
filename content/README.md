# Contenu JSON

Tout le contenu pédagogique de l'app vit ici. **Aucun code à toucher** : on
édite les JSON, on dépose les médias, on rebuild.

```
content/
├── config.json                ← nom de l'app, avatars, réglages du quiz, clavier fur
├── manifest.json              ← niveaux et catégories (couleur, emoji, pack)
├── categories/
│   ├── lettres.json                    ← l'alphabet fur (majuscules/minuscules)
│   ├── voyelles_courtes.json           ← les 8 voyelles courtes
│   ├── voyelles_longues.json           ← les 8 voyelles longues (doublées)
│   ├── voyelles_courtes_tons.json      ← voyelles courtes × 4 tons (32)
│   ├── voyelles_longues_tons.json      ← voyelles longues × 4 mélodies de ton (32)
│   ├── chiffres.json                   ← les nombres
│   ├── couleurs.json
│   ├── jours.json
│   ├── mois.json
│   └── famille.json
├── images/<catégorie>/        ← déposer les illustrations (.webp conseillé)
└── audio/<catégorie>/         ← déposer les enregistrements natifs (.m4a)
```

## Comment l'app utilise ces fichiers

- **Image** : si `images/couleurs/rouge.webp` existe, l'app l'affiche ; sinon
  elle dessine un visuel de secours (pastille de couleur, lettre, chiffre,
  mini-calendrier, emoji) → l'app est jouable même sans illustrations.
- **Audio** : le jeu est « on écoute le mot, on tape sur le bon élément ».
  Si `audio/couleurs/rouge.m4a` existe, l'app le joue ; sinon elle essaie
  `mediaBaseUrl` (CDN) ; sans aucun des deux la question reste silencieuse —
  fournir l'audio est donc essentiel.

## manifest.json

| Champ | Sens |
|-------|------|
| `mediaBaseUrl` | préfixe CDN optionnel pour les médias non embarqués |
| `levels[].title` / `subtitle` | titre du niveau sur la carte |
| `categories[].id` | identifiant, doit correspondre aux dossiers de médias |
| `categories[].kind` | `letters`, `numbers`, `colors`, `calendar` ou `words` — choisit le visuel de secours |
| `categories[].color` | couleur d'accent `#RRGGBB` de la catégorie |
| `categories[].emoji` | emoji de la tuile d'accueil |
| `categories[].pack` | chemin du JSON des mots |

Un niveau se déverrouille quand le niveau précédent totalise au moins une
étoile par catégorie.

### Voyelles et tons

Le fur distingue les voyelles **courtes** (a, a̠, e, i, ɨ, o, u, ʉ) et
**longues** (doublées : aa, a̠a̠…), et chacune peut porter un **ton** :
- Voyelle courte : plate, haute (´), descendante (^), montante (ˇ) — 4 formes.
- Voyelle longue : le ton se répartit sur les deux mores — plate-plate,
  haute-haute, haute-plate, plate-haute (`aa áá áa aá`) — 4 formes.

Ces 4 catégories (`voyelles_courtes`, `voyelles_longues`,
`voyelles_courtes_tons`, `voyelles_longues_tons`) réutilisent les mêmes
identifiants que `lettres.json` pour les voyelles de base (`a`, `a2`, `e`,
`i`, `i2`, `o`, `u`, `u2`), avec des suffixes `_h`/`_f`/`_r` (ton court) ou
`_ll`/`_hh`/`_hl`/`_lh` (ton long) pour les variantes.

## Champs d'un mot (`categories/*.json`)

| Champ | Sens |
|-------|------|
| `id` | identifiant (ne pas changer, sert à la progression) |
| `ecrit` | le mot **en fur** — à remplir par le référent linguistique (UTF-8 : Ŋ ŋ, Ɨ ɨ, Ʉ ʉ, A̠ a̠, tons) |
| `fr` | traduction française (affichée tant que `ecrit` est vide) |
| `upper` / `lower` | lettres seulement : majuscule / minuscule |
| `chiffre` | nombres seulement : le nombre en chiffres (`"42"`) |
| `hex` | couleurs seulement : la couleur `#RRGGBB` de la pastille |
| `short` | jours/mois seulement : abréviation du mini-calendrier (`LUN`, `JAN`) |
| `emoji` | famille, etc. : emoji de secours |
| `image` | chemin de l'illustration (relatif à `content/`) |
| `audio` | chemin de l'enregistrement (relatif à `content/`) |

## config.json

- `appName`, `tagline` — identité affichée dans l'app ;
- `avatars` — emojis proposés à l'enfant ;
- `quiz.questionsPerLesson`, `coinsPerCorrect`, `coinsLessonBonus` —
  économie du jeu ;
- `quiz.starThresholds` — % de bonnes réponses pour 3/2/1 étoiles.

## Ajouter une catégorie

1. Créer `categories/ma_categorie.json` (mêmes champs que ci-dessus).
2. L'ajouter dans `manifest.json` (id, titre, `kind`, couleur, emoji, pack).
3. Créer `images/ma_categorie/` et `audio/ma_categorie/` et déclarer ces deux
   dossiers dans la section `assets:` de `pubspec.yaml`.
4. `flutter test` puis rebuild.

## Notes

- Garder tous les fichiers en **UTF-8**.
- Les mauvaises réponses des QCM sont tirées de la même catégorie.
- Formats conseillés : images `.webp` carrées ≥ 512 px, audio `.m4a` (AAC).
