#!/bin/bash

BASE_DIR="/srv/karaoke"
COLA="$BASE_DIR/queue/cola.csv"
LOCK="$BASE_DIR/locks/cola.lock"
LOG="$BASE_DIR/logs/karaoke.log"
HISTORIAL="$BASE_DIR/playback/historial_reproduccion.csv"
ACTUAL="$BASE_DIR/playback/reproduccion_actual.csv"

ID_COLA="$1"
DURACION_SEG="$2"
ADMIN="$3"

if [[ -z "$ID_COLA" || -z "$DURACION_SEG" ]]; then
    exit 1
fi

sleep "$DURACION_SEG"

exec 200>"$LOCK"
flock -x 200

linea=$(awk -F, -v id="$ID_COLA" '$1 == id {print; exit}' "$COLA")

if [[ -z "$linea" ]]; then
    exit 0
fi

estado=$(echo "$linea" | awk -F, '{print $8}')

if [[ "$estado" != "reproduciendo" ]]; then
    exit 0
fi

usuario=$(echo "$linea" | awk -F, '{print $4}')
id_cancion=$(echo "$linea" | awk -F, '{print $5}')
titulo=$(echo "$linea" | awk -F, '{print $6}')
artista=$(echo "$linea" | awk -F, '{print $7}')

tmp=$(mktemp)

awk -F, -v id="$ID_COLA" 'BEGIN {OFS=","}
NR==1 {print; next}
$1==id {$8="reproducida"}
{print}
' "$COLA" > "$tmp"

cat "$tmp" > "$COLA"
rm -f "$tmp"

if [[ ! -s "$HISTORIAL" ]]; then
    echo "id_play,fecha,hora,admin,id_cola,id_cancion,titulo,artista,duracion_catalogo_seg,tiempo_reproducido_seg,estado" > "$HISTORIAL"
fi

id_play=$(tail -n +2 "$HISTORIAL" | awk -F, 'NF {id=$1} END {print id+0}')
id_play=$((id_play + 1))

printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,completa\n" \
    "$id_play" "$(date '+%F')" "$(date '+%H:%M:%S')" "$ADMIN" "$ID_COLA" "$id_cancion" "$titulo" "$artista" "$DURACION_SEG" "$DURACION_SEG" >> "$HISTORIAL"

tmp=$(mktemp)

awk -F, -v id="$ID_COLA" 'BEGIN {OFS=","}
NR==1 {print; next}
$1!=id {print}
' "$ACTUAL" > "$tmp"

cat "$tmp" > "$ACTUAL"
rm -f "$tmp"

printf "%s | INFO | sistema | finalizó reproducción simulada | %s - %s\n" "$(date '+%F %T')" "$titulo" "$artista" >> "$LOG"
