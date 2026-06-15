#!/bin/bash

BASE_DIR="/srv/karaoke"
CATALOGO="$BASE_DIR/data/catalogo.csv"
COLA="$BASE_DIR/queue/cola.csv"
LOG="$BASE_DIR/logs/karaoke.log"
LOCK="$BASE_DIR/locks/cola.lock"
REPRO_LOCK="$BASE_DIR/locks/reproduccion.lock"
PLAYBACK="$BASE_DIR/playback"
ACTUAL="$PLAYBACK/reproduccion_actual.csv"
HISTORIAL="$PLAYBACK/historial_reproduccion.csv"
PID_FILE="$PLAYBACK/sala.pid"
STOP_FILE="$PLAYBACK/sala.stop"

duracion_a_segundos() {
    local duracion="$1"
    local minutos segundos

    if [[ "$duracion" =~ ^([0-9]+):([0-9]{2})$ ]]; then
        minutos="${BASH_REMATCH[1]}"
        segundos="${BASH_REMATCH[2]}"
        echo $((10#$minutos * 60 + 10#$segundos))
    else
        echo 0
    fi
}

registrar_evento_sala() {
    local nivel="$1"
    local accion="$2"
    local detalle="$3"

    printf "%s | %s | sala | %s | %s\n" "$(date '+%F %T')" "$nivel" "$accion" "$detalle" >> "$LOG" 2>/dev/null || true
}

preparar_archivos() {
    mkdir -p "$PLAYBACK"

    if [[ ! -f "$ACTUAL" ]]; then
        echo "id_cola,usuario,id_cancion,titulo,artista,inicio,duracion_seg,estado" > "$ACTUAL"
    fi

    if [[ ! -f "$HISTORIAL" ]]; then
        echo "id_play,fecha,hora,admin,id_cola,id_cancion,titulo,artista,duracion_catalogo_seg,tiempo_reproducido_seg,estado" > "$HISTORIAL"
    fi
}

marcar_actual_vacia() {
    echo "id_cola,usuario,id_cancion,titulo,artista,inicio,duracion_seg,estado" > "$ACTUAL"
}

tomar_siguiente_pendiente() {
    local linea id_cola usuario id_cancion titulo artista duracion duracion_seg inicio tmp

    exec 200>"$LOCK"
    flock -x 200

    linea=$(tail -n +2 "$COLA" | awk -F, '$8=="pendiente" {print; exit}')

    if [[ -z "$linea" ]]; then
        flock -u 200
        return 1
    fi

    id_cola=$(echo "$linea" | awk -F, '{print $1}')
    usuario=$(echo "$linea" | awk -F, '{print $4}')
    id_cancion=$(echo "$linea" | awk -F, '{print $5}')
    titulo=$(echo "$linea" | awk -F, '{print $6}')
    artista=$(echo "$linea" | awk -F, '{print $7}')

    duracion=$(awk -F, -v id="$id_cancion" '$1 == id {print $6; exit}' "$CATALOGO")
    duracion_seg=$(duracion_a_segundos "$duracion")

    if [[ "$duracion_seg" -le 0 ]]; then
        flock -u 200
        return 1
    fi

    tmp=$(mktemp)

    awk -F, -v id="$id_cola" 'BEGIN {OFS=","}
NR==1 {print; next}
$1==id && $8=="pendiente" {$8="reproduciendo"}
{print}
' "$COLA" > "$tmp"

    cat "$tmp" > "$COLA"
    rm -f "$tmp"

    inicio="$(date '+%F %H:%M:%S')"

    {
        echo "id_cola,usuario,id_cancion,titulo,artista,inicio,duracion_seg,estado"
        echo "$id_cola,$usuario,$id_cancion,$titulo,$artista,$inicio,$duracion_seg,reproduciendo"
    } > "$ACTUAL"

    flock -u 200

    registrar_evento_sala "INFO" "inició canción en sala" "$titulo - $artista"

    return 0
}

finalizar_actual() {
    local linea id_cola usuario id_cancion titulo artista duracion_seg estado tmp id_play

    exec 200>"$LOCK"
    flock -x 200

    linea=$(tail -n +2 "$ACTUAL" | head -n 1)

    if [[ -z "$linea" ]]; then
        flock -u 200
        return
    fi

    id_cola=$(echo "$linea" | awk -F, '{print $1}')
    usuario=$(echo "$linea" | awk -F, '{print $2}')
    id_cancion=$(echo "$linea" | awk -F, '{print $3}')
    titulo=$(echo "$linea" | awk -F, '{print $4}')
    artista=$(echo "$linea" | awk -F, '{print $5}')
    duracion_seg=$(echo "$linea" | awk -F, '{print $7}')
    estado=$(echo "$linea" | awk -F, '{print $8}')

    if [[ "$estado" != "reproduciendo" ]]; then
        flock -u 200
        return
    fi

    tmp=$(mktemp)

    awk -F, -v id="$id_cola" 'BEGIN {OFS=","}
NR==1 {print; next}
$1==id {$8="reproducida"}
{print}
' "$COLA" > "$tmp"

    cat "$tmp" > "$COLA"
    rm -f "$tmp"

    id_play=$(tail -n +2 "$HISTORIAL" | awk -F, 'NF {id=$1} END {print id+0}')
    id_play=$((id_play + 1))

    printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,completa\n" \
        "$id_play" "$(date '+%F')" "$(date '+%H:%M:%S')" "sala" "$id_cola" "$id_cancion" "$titulo" "$artista" "$duracion_seg" "$duracion_seg" >> "$HISTORIAL"

    marcar_actual_vacia

    flock -u 200

    registrar_evento_sala "INFO" "finalizó canción en sala" "$titulo - $artista"
}

preparar_archivos
rm -f "$STOP_FILE"
echo $$ > "$PID_FILE"

registrar_evento_sala "INFO" "reproductor de sala iniciado" "-"

while true; do
    if [[ -f "$STOP_FILE" ]]; then
        registrar_evento_sala "INFO" "reproductor de sala detenido" "-"
        marcar_actual_vacia
        rm -f "$PID_FILE" "$STOP_FILE"
        exit 0
    fi

    if tomar_siguiente_pendiente; then
        linea_actual=$(tail -n +2 "$ACTUAL" | head -n 1)
        duracion_seg=$(echo "$linea_actual" | awk -F, '{print $7}')

        segundos=0
        while [[ "$segundos" -lt "$duracion_seg" ]]; do
            if [[ -f "$STOP_FILE" ]]; then
                registrar_evento_sala "INFO" "reproductor de sala detenido" "-"
                marcar_actual_vacia
                rm -f "$PID_FILE" "$STOP_FILE"
                exit 0
            fi

            sleep 1
            segundos=$((segundos + 1))
        done

        finalizar_actual
    else
        marcar_actual_vacia
        sleep 2
    fi
done
