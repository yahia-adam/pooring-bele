# Cahier des charges — Application d'apprentissage du fur (foor) pour enfants

**Nom de code du projet :** `pooring-bele`
**Version du document :** 1.0 — 6 août 2026
**Type de livrable :** API + application Flutter (mobile Android/iOS + web)

---

## 1. Vision et objectifs

### 1.1 Le problème
Le fur (aussi écrit *foor*, *poor*, autonyme *fòòr*) est une langue nilo-saharienne parlée par environ 744 000 personnes dans les États du Nord, Sud et Ouest Darfour, au Soudan. Comme beaucoup de langues minoritaires, elle est peu enseignée à l'écrit et se transmet surtout à l'oral. Les enfants de la diaspora et des villes risquent de perdre leur langue maternelle faute d'outils modernes et ludiques.

### 1.2 L'objectif
Créer une application mobile et web qui permet à un enfant (5–12 ans) d'apprendre et de renforcer le vocabulaire fur de façon **ludique, visuelle et sonore**, sur le modèle des apps de vocabulaire par images (voir §2). L'apprentissage se fait par **reconnaissance image ↔ mot ↔ son**, sans dépendre de la capacité de lecture de l'enfant.

### 1.3 Principes directeurs
- **L'audio d'abord.** L'enfant doit toujours pouvoir entendre le mot prononcé par un locuteur natif. Le fur est une langue à tons : la prononciation enregistrée est indispensable (pas de synthèse vocale disponible).
- **L'image d'abord.** Chaque mot est associé à une illustration claire. On n'exige jamais de lire pour progresser au début.
- **Bilingue de transition.** Interface et traductions disponibles en français et/ou arabe (langues de scolarisation au Soudan et dans la diaspora francophone), pour que l'enfant relie le fur à une langue qu'il connaît déjà.
- **Progression gratifiante.** Étoiles, pièces, niveaux : chaque petite victoire est célébrée.
- **Hors-ligne friendly.** Les enfants ciblés n'ont pas toujours une connexion stable ; le contenu d'une leçon doit pouvoir être téléchargé et joué hors ligne.

---

## 2. Analyse de l'application modèle (captures fournies)

L'analyse des 10 captures du dossier `screen_fonctionnalites` révèle une application de **vocabulaire par images organisée en niveaux**. Fonctionnalités identifiées :

### 2.1 Structure de navigation
- **Écran d'accueil par niveau** (`LEVEL 1`, `LEVEL 2`, `LEVEL 3`…) présenté comme un parcours vertical avec des jalons numérotés (1, 2, 3…) reliés par une ligne, façon « carte du voyage ».
- Chaque niveau contient une grille de **catégories thématiques** affichées en tuiles (image + titre).
- Chaque tuile de catégorie affiche **3 étoiles** indiquant le niveau de maîtrise atteint (grises = non fait, dorées = réussi).

### 2.2 Barre supérieure (statut du joueur)
Persistante en haut de l'accueil : compteur d'**étoiles** ⭐, de **gemmes/diamants** 💎, de **pièces** 🪙, et **avatar + prénom** du joueur (ex. « JEAN »).

### 2.3 Catégories observées
Level 1 : Alphabet, Nombres, Couleurs, Verbes, Aliments, Légumes, Fruits, Boissons et sucreries.
Level 2 : Transport, Animaux sauvages, Animaux de la ferme, Animaux marins, Animaux domestiques, Insectes, Jours de la semaine, Mois et saisons.
Level 3 : Vêtements, Vacances, Sports, Ville, Chambre, Salle de bain, Cuisine, Salon.
Autres vues : École (salle de classe, élève, professeur, crayon, stylo, gomme, calculatrice…).

### 2.4 Types d'exercices identifiés
| # | Type | Description | Capture |
|---|------|-------------|---------|
| A | **Audio → Image** | On entend le mot, on choisit la bonne image parmi 4. | Animaux sauvages (2/10) |
| B | **Mot → Image** | Le mot est écrit, on choisit la bonne image parmi 4. | Transport « AVION » (1/10) |
| C | **Image → Mot** | Une image est montrée, on choisit le bon mot parmi 4 boutons. | Verbes, Vêtements « ROBE » |
| D | **Dictée / Épellation** | Audio + image, on reconstitue le mot avec des lettres-tuiles (clavier). | Aliments « FROMAGE » (8/10) |
| E | **Découverte / Imagier** | Grille d'images + mots à parcourir, sans quiz (mode apprentissage). | Boissons, École |

### 2.5 Mécaniques de jeu
- **Barre de progression** par leçon (`2/10`, `8/10`, `5/19`, `8/21`…).
- **Bouton indice** (ampoule) dans les exercices difficiles, avec un **coût en pièces** (ex. « 5 »).
- **Récompenses** en pièces à la fin d'une leçon.
- **Code couleur par catégorie** (chaque catégorie a sa couleur d'accent : vert pour les animaux, orange pour les aliments, violet pour les vêtements…).
- **Étoiles de maîtrise** (jusqu'à 3) attribuées selon le score obtenu dans la leçon.

Ces mécaniques constituent le socle fonctionnel à reproduire pour le fur.

---

## 3. Spécificités de la langue fur à prendre en compte

Ces contraintes linguistiques ont un impact direct sur la conception :

1. **Langue à tons.** Le fur est tonal ; le sens peut changer selon la hauteur. → L'**audio enregistré par des locuteurs natifs est obligatoire** pour chaque mot. La synthèse vocale (TTS) n'existe pas pour le fur et ne doit pas être utilisée.
2. **Alphabet latin étendu.** Le fur s'écrit en alphabet latin. Il utilise des caractères particuliers (par ex. **ŋ**) et les **voyelles longues se notent en doublant la voyelle** (ex. *fòòr*). → Le clavier de l'exercice de dictée (type D) doit inclure ces caractères ; les polices doivent supporter l'Unicode étendu et éventuellement les marques tonales (diacritiques).
3. **Orthographe non figée.** Il peut exister des variantes orthographiques. → Prévoir dans le modèle de données un champ « variantes acceptées » pour la validation des réponses écrites, et faire valider le corpus par un référent linguistique.
4. **Public non-lecteur.** Beaucoup d'enfants ciblés ne lisent pas encore le fur (langue rarement scolarisée). → Les exercices écrits (type D) arrivent tard dans la progression ; l'audio et l'image priment.
5. **Direction d'écriture.** Le fur s'écrit de gauche à droite (latin), mais si une version arabe de l'interface est proposée, prévoir le support **RTL** de Flutter.

> ⚠️ **Point critique du projet : le contenu.** La partie la plus lourde n'est pas le code mais la **constitution du corpus** : traductions fur validées + enregistrements audio natifs + illustrations. Ce cahier des charges prévoit un back-office pour gérer ce corpus (§6.3).

---

## 4. Périmètre fonctionnel

### 4.1 MVP (version 1)
- Parcours en niveaux avec catégories thématiques (5–8 catégories pour commencer).
- Les 3 types d'exercices de base : **A (audio→image)**, **C (image→mot)**, **E (imagier de découverte)**.
- Audio natif pour chaque mot + illustrations.
- Système d'étoiles de maîtrise et de progression par leçon.
- Profil enfant local (prénom + avatar), pièces et récompenses.
- Mode hors-ligne : téléchargement d'une catégorie.
- Interface bilingue fur ↔ français (et/ou arabe).

### 4.2 Version 2
- Exercices **B (mot→image)** et **D (dictée/épellation)** avec clavier fur étendu.
- Bouton indice avec coût en pièces.
- Gemmes, boutique d'avatars, séries quotidiennes (streaks).
- Comptes multi-enfants (un parent, plusieurs profils).
- Synchronisation cloud de la progression.

### 4.3 Version 3 (idées futures)
- Mode « phrases » (petites phrases, salutations, dialogues).
- Prononciation par l'enfant (enregistrement + comparaison simple).
- Contenu culturel (chansons, contes du Darfour).
- Espace enseignant / classe.

### 4.4 Hors périmètre (à exclure explicitement)
- Pas de messagerie ni de fonction sociale (public enfant → sécurité).
- Pas de publicité ciblée ni de collecte de données personnelles au-delà du strict nécessaire.
- Pas de synthèse vocale automatique du fur.

---

## 5. Parcours utilisateur et écrans

1. **Onboarding** : choix de la langue d'interface (fr/ar), création du profil (prénom + avatar), courte démo.
2. **Carte des niveaux** : parcours vertical, niveaux déverrouillés progressivement.
3. **Grille de catégories** d'un niveau, avec étoiles de maîtrise.
4. **Écran de leçon** : suite d'exercices (barre de progression x/n).
5. **Écran de fin de leçon** : étoiles gagnées, pièces, bouton « rejouer » / « continuer ».
6. **Profil** : statistiques, pièces, gemmes, avatar.
7. **Réglages parents** (verrouillé par une question simple) : gestion des profils, téléchargements hors-ligne, langue.

---

## 6. Architecture technique

### 6.1 Vue d'ensemble
```
┌──────────────────────────┐        ┌──────────────────────────┐
│   App Flutter (mobile +  │        │   Back-office web (admin)│
│   web) — client apprenant│        │   gestion du corpus      │
└────────────┬─────────────┘        └────────────┬─────────────┘
             │  HTTPS / REST (JSON)               │
             ▼                                    ▼
        ┌─────────────────────────────────────────────┐
        │              API (backend)                   │
        │  Auth · Contenu · Progression · Médias       │
        └───────────────┬──────────────┬───────────────┘
                        ▼              ▼
                 ┌────────────┐  ┌──────────────────┐
                 │ Base de    │  │ Stockage médias  │
                 │ données    │  │ (audio + images) │
                 └────────────┘  └──────────────────┘
```

### 6.2 Application Flutter (client)
- **Un seul code base** pour Android, iOS et Web (Flutter).
- **Gestion d'état** : Riverpod (ou Bloc) — recommandé Riverpod pour la simplicité.
- **Navigation** : go_router.
- **Audio** : `just_audio` (lecture) ; `audioplayers` en alternative.
- **Stockage local / hors-ligne** : `drift` (SQLite) ou `isar` pour le contenu ; `hive` pour les préférences ; `flutter_cache_manager` pour les médias téléchargés.
- **Internationalisation** : `flutter_localizations` + fichiers ARB (fr, ar, et fur pour les libellés).
- **Polices** : police supportant l'Unicode latin étendu (ŋ, diacritiques) — ex. Noto Sans.
- **Animations/gamification** : `lottie` pour les récompenses.

Architecture applicative recommandée : **feature-first + clean architecture légère** (couche `data` / `domain` / `presentation`), pour isoler l'API et permettre le mode hors-ligne (repository qui bascule entre cache local et réseau).

### 6.3 Back-office d'administration du contenu
Outil web (peut être une seconde app Flutter Web, ou un CMS type Directus/Strapi pour aller plus vite) permettant à l'équipe pédagogique de :
- créer les niveaux, catégories et mots ;
- saisir la traduction fur, la ou les variantes orthographiques acceptées, la traduction fr/ar ;
- **téléverser l'audio natif** et l'**illustration** de chaque mot ;
- construire les leçons (choix des mots, type d'exercice, ordre) ;
- prévisualiser et publier.

> Recommandation : pour accélérer le MVP, utiliser un CMS headless (**Directus** ou **Strapi**) comme back-office + base de données + API de contenu, et coder une API métier légère par-dessus pour la progression/gamification. Cela évite de développer un CMS from scratch.

### 6.4 API (backend)
- **Techno suggérée** : Node.js (NestJS) ou Python (FastAPI) — les deux exposent facilement du REST/JSON et gèrent bien les médias. Choisir selon les compétences de l'équipe.
- **Base de données** : PostgreSQL (relationnel, adapté au contenu structuré).
- **Stockage médias** : un bucket objet (S3, Cloudflare R2, ou MinIO auto-hébergé) servant l'audio et les images via CDN.
- **Auth** : légère. Pour un public enfant, privilégier un **compte parent** (email + mot de passe, ou lien magique) qui gère des profils enfants. Pas de login social enfant.
- **Format** : API REST versionnée (`/api/v1/…`), réponses JSON, pagination, ETag/Cache-Control pour le contenu (peu changeant).

### 6.5 Points d'API principaux (esquisse)
```
GET  /api/v1/levels                     → liste des niveaux + catégories
GET  /api/v1/categories/{id}/lessons    → leçons d'une catégorie
GET  /api/v1/lessons/{id}               → détail leçon (mots, exercices, URLs médias)
GET  /api/v1/content/pack/{categoryId}  → pack téléchargeable hors-ligne (JSON + liste médias)

POST /api/v1/auth/parent                → connexion parent
GET  /api/v1/profiles                   → profils enfants du compte
POST /api/v1/profiles                   → créer un profil enfant

GET  /api/v1/progress/{profileId}       → progression (étoiles, pièces, niveaux)
POST /api/v1/progress/{profileId}/lesson→ enregistrer le résultat d'une leçon
```

---

## 7. Modèle de données (esquisse)

```
Level        (id, ordre, titre_i18n, est_verrouillé)
Category     (id, level_id, ordre, titre_i18n, couleur, icône)
Word         (id, category_id,
              fur_texte,               -- ex. "fòòr"
              fur_variantes[],         -- orthographes acceptées
              traduction_i18n,         -- {fr:"...", ar:"..."}
              audio_url,               -- enregistrement natif OBLIGATOIRE
              image_url,
              tags[])
Lesson       (id, category_id, ordre, type_exercice[A|B|C|D|E], liste_word_id[])
Exercise     (généré à partir de Lesson : question, bonne réponse, distracteurs)

Parent       (id, email, hash_mdp)
ChildProfile (id, parent_id, prénom, avatar, langue_interface)
Progress     (profile_id, lesson_id, étoiles 0-3, score, pièces_gagnées, date)
Wallet       (profile_id, pièces, gemmes)
```

Les distracteurs (mauvaises réponses des QCM A/B/C) sont de préférence tirés **de la même catégorie** pour un contraste pertinent.

---

## 8. Contenu pédagogique

### 8.1 Progression proposée (à valider avec un référent fur)
- **Niveau 1 — Bases visuelles :** couleurs, nombres 1–10, formes, animaux familiers.
- **Niveau 2 — Le quotidien :** aliments, boissons, corps humain, famille, vêtements.
- **Niveau 3 — Autour de moi :** maison, école, village/ville, transport.
- **Niveau 4 — Le monde :** animaux sauvages, plantes, météo, jours/mois/saisons.
- **Niveau 5 — Verbes et actions**, puis petites phrases et salutations.

### 8.2 Volume cible du MVP
5 catégories × ~12 mots = **~60 mots**, chacun avec : texte fur validé, traduction, **1 enregistrement audio natif**, **1 illustration**. C'est l'effort principal du projet.

### 8.3 Production du corpus (chantier critique)
- Recruter un ou deux **locuteurs natifs référents** (idéalement enseignants ou linguistes fur) pour valider l'orthographe et enregistrer l'audio.
- Protocole d'enregistrement simple (smartphone correct + appli d'enregistrement, pièce silencieuse, format WAV puis compression).
- Illustrations : style cohérent, culturellement adapté au Darfour quand c'est pertinent (objets, habits, animaux locaux plutôt que génériques).

---

## 9. Contraintes transverses

- **Accessibilité enfant** : gros boutons, peu de texte, tout est audio-cliquable, pas de minuterie stressante.
- **Sécurité & vie privée** : conformité RGPD/COPPA pour un public mineur ; pas de pub, pas de tracking tiers, données minimales, contrôle parental. Consentement parental à l'inscription.
- **Hors-ligne** : une catégorie téléchargée doit fonctionner sans réseau (contenu + médias en cache local).
- **Performance** : médias servis via CDN, images optimisées (WebP), audio compressé (AAC/Opus).
- **Internationalisation** : interface fr/ar dès le MVP, extensible ; support RTL si arabe.
- **Localisation des polices** : vérifier le rendu des caractères fur spéciaux sur toutes les plateformes.

---

## 10. Roadmap indicative

| Phase | Contenu | Livrable |
|-------|---------|----------|
| **0 — Cadrage** | Validation du corpus initial, recrutement du référent fur, choix techno définitif | Corpus 60 mots planifié, maquettes |
| **1 — Fondations** | API + modèle de données + back-office contenu + 1 catégorie de démo | Une leçon jouable de bout en bout |
| **2 — MVP** | App Flutter (exercices A, C, E), gamification de base, hors-ligne, 5 catégories | App testable (Android + web) |
| **3 — V2** | Exercices B et D (clavier fur), gemmes/boutique, multi-profils, sync cloud | App enrichie |
| **4 — Lancement** | Tests utilisateurs enfants, corrections, publication stores + web | Version publique |

---

## 11. Risques et points de vigilance

1. **Disponibilité du corpus fur** (traductions + audio) = risque n°1. Sécuriser les référents linguistiques avant de coder à grande échelle.
2. **Variabilité orthographique** du fur : figer une convention avec le référent, gérer les variantes en base.
3. **Public non-lecteur** : ne pas surestimer la lecture ; audio/image priment longtemps.
4. **Illustrations culturellement adaptées** : éviter des images génériques déconnectées du contexte darfourien.
5. **Connectivité faible** du public cible : le hors-ligne n'est pas optionnel.

---

## 12. Prochaines étapes concrètes

1. Valider ce cahier des charges (périmètre MVP, langues d'interface, techno backend).
2. Identifier le·s référent·s fur et lancer la constitution du corpus des ~60 premiers mots.
3. Choisir : back-office « fait maison » vs CMS headless (Directus/Strapi) — je recommande le CMS pour le MVP.
4. Produire les maquettes des écrans clés (carte des niveaux, grille de catégories, les 3 types d'exercices du MVP).
5. Démarrer la Phase 1 (API + une catégorie de démo).

---

*Document de travail — à affiner avec un référent linguistique fur et selon les choix techniques définitifs de l'équipe.*
