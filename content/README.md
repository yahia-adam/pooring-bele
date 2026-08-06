# Contenu JSON

```
content/
├── manifest.json              ← liste des niveaux et catégories
└── categories/
    ├── lettres.json           ← les 26 lettres du fur
    └── chiffres.json          ← les nombres (0→100, puis 200…900, 1000 … 1 000 000 000)
```

## Champs d'une lettre
| Champ | Sens |
|-------|------|
| `id` | identifiant (ne pas changer) |
| `upper` | la lettre en MAJUSCULE |
| `lower` | la lettre en minuscule |
| `image` | fichier image |
| `audio` | fichier son |

## Champs d'un chiffre
| Champ | Sens |
|-------|------|
| `id` | identifiant |
| `chiffre` | le nombre écrit **en chiffres** (ex. `"42"`) — universel |
| `ecrit` | le nombre écrit **en toutes lettres, en fur** (ex. `dííg`) — **à remplir par toi** |
| `image` | fichier image |
| `audio` | fichier son |

## À faire par toi
- Remplir le champ `ecrit` des chiffres (le mot en fur).
- Fournir les fichiers `image` et `audio`.

## Notes
- `manifest.json` : les catégories et le chemin de chaque pack. `mediaBaseUrl` = préfixe commun aux `image`/`audio`.
- Je ne peux pas lister chaque entier jusqu'à un milliard (ça ferait un milliard de lignes). J'ai mis 0→100 un par un, puis les centaines et les paliers (1000, 10000 … 1 000 000 000). Ajoute les nombres précis dont tu as besoin, ou compose-les dans l'app.
- Caractères spéciaux (`Ŋ ŋ`, `Ɨ ɨ`, `Ʉ ʉ`, `A̠ a̠`) : garde les fichiers en UTF-8.
