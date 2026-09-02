#!/usr/bin/env bash
# Nettoyage audio non destructif pour les enregistrements de l'app.
#
# Chaine de traitement (par fichier, tout est dose sur des mesures reelles) :
#   1. highpass 70 Hz   -> rumble / souffle de manip, sous la voix
#   2. afftdn adaptatif -> debruitage dose selon le SNR mesure, plafonne a NR_MAX
#   3. trim + padding   -> coupe les silences aux extremites, remet un pad fixe
#   4. gain lineaire    -> amene tout a TARGET LUFS, sans compression
#   5. alimiter         -> filet anti-ecretage uniquement
#
# Le gain est calcule sur le signal DEJA filtre et rogne : sinon le filtrage
# decale le loudness et la cible est ratee de pres d'un dB.
#
# Les originaux ne sont jamais modifies : la sortie va dans un dossier separe.

set -uo pipefail

SRC="content/audio"
DST="content/audio_clean"
TARGET=-16.0        # LUFS vise (standard mobile / podcast)
TP_CEIL=-1.5        # plafond true-peak en dBTP
MAX_LIMIT=5.0       # limiting max tolere avant de reduire le gain
NR_MAX=14           # reduction de bruit max en dB (au dela : artefacts metalliques)
HPF=70              # coupure passe-haut en Hz
PAD_HEAD=0.05       # silence ajoute en tete (s)
PAD_TAIL=0.15       # silence ajoute en queue (s)
TRIM_MARGIN=0.06    # marge de securite conservee autour de la parole (s)
MIN_SPEECH=0.15     # garde-fou : jamais rogner en dessous de cette duree
TRIM=1
DRYRUN=0
ONLY=""

usage() {
  cat <<'EOF'
Usage: tools/clean_audio.sh [options]
  --in DIR        dossier source        (defaut: content/audio)
  --out DIR       dossier sortie        (defaut: content/audio_clean)
  --target LUFS   cible de loudness     (defaut: -16)
  --nr-max DB     debruitage max en dB  (defaut: 14, 0 = desactive)
  --no-trim       ne pas rogner les silences
  --only PATTERN  ne traiter que les chemins contenant PATTERN
  --dry-run       mesurer sans encoder
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --in) SRC="$2"; shift 2;;
    --out) DST="$2"; shift 2;;
    --target) TARGET="$2"; shift 2;;
    --nr-max) NR_MAX="$2"; shift 2;;
    --no-trim) TRIM=0; shift;;
    --only) ONLY="$2"; shift 2;;
    --dry-run) DRYRUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "option inconnue: $1" >&2; usage; exit 1;;
  esac
done

command -v ffmpeg >/dev/null || { echo "ffmpeg introuvable" >&2; exit 1; }

FF="ffmpeg -hide_banner -nostdin -nostats"

# Loudness integre EBU R128 + true peak. Accepte une chaine de filtres optionnelle
# a appliquer avant la mesure.
measure() {
  local f="$1" pre="${2:-}"
  local af="loudnorm=I=${TARGET}:TP=${TP_CEIL}:LRA=11:print_format=json"
  [ -n "$pre" ] && af="${pre},${af}"
  $FF -i "$f" -af "$af" -f null - 2>&1 \
  | awk '/"input_i"/  {gsub(/[",]/,""); i=$NF}
         /"input_tp"/ {gsub(/[",]/,""); t=$NF}
         END {printf "%s %s", (i==""?"na":i), (t==""?"na":t)}'
}

REPORT="$DST/_rapport.tsv"
HDR="fichier\tI_avant\tI_apres\tTP_apres\tplancher\tSNR\tdense\tNR_dB\tgain_dB\tlimit_dB\tcoupe_tete\tcoupe_queue\tdur_avant\tdur_apres"
if [ "$DRYRUN" -eq 0 ]; then mkdir -p "$DST"; printf "$HDR\n" > "$REPORT"; else printf "$HDR\n"; fi

total=0; done_n=0; skipped=0
files=$(find "$SRC" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' -o -iname '*.aac' \) | sort)
[ -n "$ONLY" ] && files=$(printf '%s\n' "$files" | grep -- "$ONLY")

for f in $files; do
  total=$((total+1))
  rel="${f#$SRC/}"
  out="$DST/$rel"

  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  sr=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$f")

  # Profil de bruit par percentiles sur des fenetres de 50 ms.
  # Le "Noise floor" d astats est inutilisable ici : sur une voyelle tenue sans
  # aucun silence il mesure le creux de la voix, pas le bruit, et fait surdoser
  # le debruitage sur precisement les sons qu il ne faut pas abimer.
  read -r P10 P50 P90 NWIN <<< "$($FF -i "$f" \
      -af "asetnsamples=n=$((sr/20)),astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" \
      -f null - 2>/dev/null \
    | awk -F= '/RMS_level/{v=$2+0; if(v>-200) a[++n]=v}
        function pct(p,   k) { k=int(n*p+0.5); if(k<1)k=1; if(k>n)k=n; return a[k] }
        END{ if(n<1){print "-60 -40 -20 0"; exit}
             for(i=1;i<n;i++) for(j=1;j<=n-i;j++) if(a[j]>a[j+1]){t=a[j];a[j]=a[j+1];a[j+1]=t}
             printf "%.1f %.1f %.1f %d", pct(0.10), pct(0.50), pct(0.90), n }')"
  nf="$P10"
  # Un clip "dense" (aucun creux marque) n a pas de silence ou un bruit serait
  # audible : on n y touche presque pas et on ne le rogne pas.
  dense=$(awk -v p50="$P50" -v p10="$P10" -v n="$NWIN" 'BEGIN{print (n<5 || p50-p10 < 12) ? 1 : 0}')

  read -r I0 TP0 <<< "$(measure "$f")"
  if [ "$I0" = "na" ] || [ "$I0" = "-inf" ]; then
    echo "  ! mesure impossible, copie telle quelle: $rel" >&2
    [ "$DRYRUN" -eq 0 ] && { mkdir -p "$(dirname "$out")"; cp "$f" "$out"; }
    skipped=$((skipped+1)); continue
  fi

  # --- dosage du debruitage selon le SNR reel : un enregistrement propre
  #     est a peine touche, seuls les mauvais sont traites fort ---
  read -r snr nr nf_c <<< "$(awk -v hi="$P90" -v lo="$P10" -v d="$dense" -v mx="$NR_MAX" 'BEGIN{
      s = hi - lo;                      # SNR reel : parole vs passages calmes
      if      (s >= 35) r = 0;          # deja propre : ne rien faire
      else if (s >= 25) r = 4;
      else if (s >= 18) r = 8;
      else              r = 12;
      if (d == 1 && r > 6) r = 6;       # pas de silence isole : bruit non percu
      if (r > mx) r = mx;
      c = lo; if (c < -80) c = -80; if (c > -20) c = -20;
      printf "%.1f %.1f %.1f", s, r, c }')"

  chain="highpass=f=${HPF}:poles=2"
  awk -v r="$nr" 'BEGIN{exit !(r>0.5)}' && chain="${chain},afftdn=nf=${nf_c}:nr=${nr}:tn=1"

  # --- bornes de parole, detectees sur le signal deja debruite ---
  S=0; E="$dur"
  # Un clip dense n a pas de silence aux extremites : le rogner ne peut que
  # mordre sur la voix, donc on s abstient.
  do_trim=0
  [ "$TRIM" -eq 1 ] && [ "$dense" -eq 0 ] && do_trim=1
  if [ "$do_trim" -eq 1 ]; then
    # seuil place entre le plancher reel et la parole, jamais assez haut
    # pour attraper un phoneme faible
    thr=$(awk -v lo="$P10" -v hi="$P90" 'BEGIN{v=hi-30; f=lo+6; printf "%.1f", (v>f?v:f)}')
    read -r S E <<< "$($FF -i "$f" -af "${chain},silencedetect=n=${thr}dB:d=0.04" -f null - 2>&1 \
      | awk -v dur="$dur" -v m="$TRIM_MARGIN" -v mins="$MIN_SPEECH" '
          /silence_start:/ { for(i=1;i<=NF;i++) if($i=="silence_start:") { n++; ss[n]=$(i+1)+0; se[n]=-1 } }
          /silence_end:/   { for(i=1;i<=NF;i++) if($i=="silence_end:")   { if(n>0) se[n]=$(i+1)+0 } }
          END {
            s = 0; e = dur
            # silence de tete : premier bloc colle au debut du fichier
            if (n > 0 && ss[1] <= 0.05 && se[1] > 0) s = se[1] - m
            # silence de queue : dernier bloc qui court jusqu a la fin
            if (n > 0 && (se[n] < 0 || se[n] >= dur - 0.05) && ss[n] > s + 0.05) e = ss[n] + m
            if (s < 0)   s = 0
            if (e > dur) e = dur
            if (e - s < mins) { s = 0; e = dur }
            printf "%.3f %.3f", s, e }')"
    [ -z "${S:-}" ] && { S=0; E="$dur"; }
    chain="${chain},atrim=start=${S}:end=${E},asetpts=N/SR/TB"
  fi
  # Fades tres courts (inaudibles sur de la voix) : suppriment tout clic a la
  # jonction avec le silence ajoute, que le fichier ait ete rogne ou non.
  span=$(awk -v s="$S" -v e="$E" 'BEGIN{printf "%.3f", e-s}')
  fout=$(awk -v sp="$span" 'BEGIN{v=sp-0.015; printf "%.3f", (v>0?v:0)}')
  chain="${chain},afade=t=in:st=0:d=0.008,afade=t=out:st=${fout}:d=0.015"
  # le padding entre dans la chaine avant la mesure : ajoute apres, le silence
  # dilue le LUFS integre et la cible est ratee de pres d un demi dB
  chain="${chain},adelay=$(awk -v p="$PAD_HEAD" 'BEGIN{printf "%d", p*1000}'):all=1,apad=pad_dur=${PAD_TAIL}"
  cut_h=$(awk -v s="$S" 'BEGIN{printf "%.2f", s}')
  cut_t=$(awk -v e="$E" -v d="$dur" 'BEGIN{v=d-e; printf "%.2f", (v>0?v:0)}')

  # --- gain calcule sur le signal filtre et rogne, pas sur le fichier brut ---
  read -r I1 TP1 <<< "$(measure "$f" "$chain")"
  [ "$I1" = "na" ] && { I1="$I0"; TP1="$TP0"; }

  read -r gain lim <<< "$(awk -v i="$I1" -v tp="$TP1" -v t="$TARGET" -v c="$TP_CEIL" -v ml="$MAX_LIMIT" 'BEGIN{
      g = t - i;
      over = (tp + g) - c;              # depassement du plafond apres gain
      if (over > ml) g -= (over - ml);  # trop : on baisse plutot que d ecraser
      over = (tp + g) - c; if (over < 0) over = 0;
      printf "%.2f %.2f", g, over }')"

  base="$chain"

  if [ "$DRYRUN" -eq 1 ]; then
    printf "%s\t%s\t-\t-\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\t-\n" \
      "$rel" "$I0" "$nf" "$snr" "$dense" "$nr" "$gain" "$lim" "$cut_h" "$cut_t" "$dur"
    continue
  fi

  mkdir -p "$(dirname "$out")"
  case "${f##*.}" in
    mp3|MP3) enc=(-c:a libmp3lame -q:a 2);;
    wav|WAV) enc=(-c:a pcm_s16le);;
    *)       enc=(-c:a aac -b:a 128k -movflags +faststart);;
  esac

  # Encode, remesure le resultat reel, corrige le gain si la cible est ratee.
  # Sur des clips d une seconde la mesure R128 (blocs de 400 ms + gating) n est
  # pas exactement reproductible entre le filtergraph et le fichier encode.
  # On repart toujours de la source : une seule generation d encodage lossy.
  Ia=na; TPa=na
  for pass in 1 2 3; do
    chain="${base},volume=${gain}dB,alimiter=limit=${TP_CEIL}dB:attack=1:release=40:level=disabled"
    if ! $FF -loglevel error -y -i "$f" -af "$chain" -ac 1 -ar "$sr" "${enc[@]}" "$out" 2>/dev/null; then
      Ia=fail; break
    fi
    read -r Ia TPa <<< "$(measure "$out")"
    [ "$Ia" = "na" ] || [ "$Ia" = "-inf" ] && break
    delta=$(awk -v t="$TARGET" -v a="$Ia" 'BEGIN{printf "%.2f", t-a}')
    awk -v d="$delta" 'BEGIN{exit !(d<0.25 && d>-0.25)}' && break
    # ne pas gagner en precision au prix d un ecrasement des cretes
    next_lim=$(awk -v tp="$TP1" -v g="$gain" -v d="$delta" -v c="$TP_CEIL" 'BEGIN{v=(tp+g+d)-c; printf "%.2f", (v>0?v:0)}')
    awk -v l="$next_lim" -v ml="$MAX_LIMIT" 'BEGIN{exit !(l>ml)}' && break
    gain=$(awk -v g="$gain" -v d="$delta" 'BEGIN{printf "%.2f", g+d}')
  done
  if [ "$Ia" = "fail" ]; then
    echo "  ! encodage echoue, copie telle quelle: $rel" >&2
    cp "$f" "$out"; skipped=$((skipped+1)); continue
  fi
  lim=$(awk -v tp="$TP1" -v g="$gain" -v c="$TP_CEIL" 'BEGIN{v=(tp+g)-c; printf "%.2f", (v>0?v:0)}')
  d1=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out")
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%.2f\t%.2f\n" \
    "$rel" "$I0" "$Ia" "$TPa" "$nf" "$snr" "$dense" "$nr" "$gain" "$lim" "$cut_h" "$cut_t" "$dur" "$d1" >> "$REPORT"
  done_n=$((done_n+1))
  printf "\r  %d/%d  %-50s" "$done_n" "$total" "$rel"
done

echo
echo "Termine: $done_n traites, $skipped copies sans traitement, sur $total."
[ "$DRYRUN" -eq 0 ] && echo "Rapport: $REPORT"
exit 0
