#!/usr/bin/env bash
# Bascule les fichiers traites vers content/audio/ (le dossier lu par l app).
#
# Les enregistrements d origine sont d abord copies dans audio_master/, place
# hors de content/ pour ne jamais etre embarque dans le bundle Flutter.
# Ce sont les seuls masters : ne les supprime pas, tout retraitement repart
# de la, jamais d un fichier deja traite (le lossy ne se reencode pas
# indefiniment sans perte).
#
#   tools/apply_audio.sh            applique la version nettoyee
#   tools/apply_audio.sh --revert   restaure les originaux

set -euo pipefail

SRC="content/audio_clean"
DST="content/audio"
MASTER="audio_master"

if [ "${1:-}" = "--revert" ]; then
  [ -d "$MASTER" ] || { echo "Aucune sauvegarde dans $MASTER/ : rien a restaurer." >&2; exit 1; }
  n=0
  while IFS= read -r f; do
    rel="${f#$MASTER/}"
    mkdir -p "$(dirname "$DST/$rel")"
    cp "$f" "$DST/$rel"
    n=$((n+1))
  done < <(find "$MASTER" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' \))
  echo "Restaure : $n fichiers d origine remis dans $DST/."
  exit 0
fi

[ -d "$SRC" ] || { echo "$SRC/ absent : lance d abord tools/clean_audio.sh" >&2; exit 1; }

# Sauvegarde unique : ne jamais ecraser les masters avec des fichiers deja traites.
if [ -d "$MASTER" ]; then
  echo "Sauvegarde deja presente dans $MASTER/, conservee telle quelle."
else
  mkdir -p "$MASTER"
  n=0
  while IFS= read -r f; do
    rel="${f#$DST/}"
    mkdir -p "$(dirname "$MASTER/$rel")"
    cp "$f" "$MASTER/$rel"
    n=$((n+1))
  done < <(find "$DST" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' \))
  echo "Originaux sauvegardes : $n fichiers dans $MASTER/."
fi

n=0
while IFS= read -r f; do
  rel="${f#$SRC/}"
  case "$rel" in _*|*/_*) continue;; esac   # ignore _rapport.tsv et _comparaison/
  mkdir -p "$(dirname "$DST/$rel")"
  cp "$f" "$DST/$rel"
  n=$((n+1))
done < <(find "$SRC" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' \))

echo "Applique : $n fichiers nettoyes copies dans $DST/."
echo "Pour revenir en arriere : tools/apply_audio.sh --revert"
