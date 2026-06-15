#!/bin/bash

BASE_DIR="/srv/karaoke"
CATALOGO="$BASE_DIR/data/catalogo.csv"
COLA="$BASE_DIR/queue/cola.csv"
LOG="$BASE_DIR/logs/karaoke.log"
LOCK="$BASE_DIR/locks/cola.lock"
REPORTS="$BASE_DIR/reports"

pausa() {
    read -rp "Presiona ENTER para continuar..." _
}

registrar_evento() {
    local nivel="$1"
    local accion="$2"
    local detalle="$3"

    printf "%s | %s | %s | %s | %s\n" "$(date '+%F %T')" "$nivel" "$USER" "$accion" "$detalle" >> "$LOG" 2>/dev/null || true
}

mostrar_catalogo() {
    column -t -s, "$CATALOGO"
    registrar_evento "INFO" "consultó catálogo" "-"
}

buscar_cancion() {
    read -rp "Buscar por título, artista, álbum o género: " termino

    if [[ -z "$termino" ]]; then
        echo "No escribiste ningún término de búsqueda."
        return
    fi

    {
        head -n 1 "$CATALOGO"
        tail -n +2 "$CATALOGO" | grep -i -- "$termino"
    } | column -t -s,

    registrar_evento "INFO" "buscó canción" "$termino"
}

ver_cola() {
    if [[ $(wc -l < "$COLA") -le 1 ]]; then
        echo "La cola está vacía."
    else
        column -t -s, "$COLA"
    fi

    registrar_evento "INFO" "consultó cola" "-"
}

siguiente_id_cola() {
    local ultimo
    ultimo=$(tail -n +2 "$COLA" | awk -F, 'NF {id=$1} END {print id+0}')
    echo $((ultimo + 1))
}

solicitar_cancion() {
    mostrar_catalogo
    echo
    read -rp "Escribe el ID de la canción a solicitar: " id

    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "ID inválido."
        return
    fi

    local linea estado titulo artista fecha hora id_cola

    linea=$(awk -F, -v id="$id" '$1 == id {print; exit}' "$CATALOGO")

    if [[ -z "$linea" ]]; then
        echo "No existe una canción con ese ID."
        return
    fi

    estado=$(echo "$linea" | awk -F, '{print $7}')

    if [[ "$estado" != "activo" ]]; then
        echo "La canción no está activa."
        return
    fi

    titulo=$(echo "$linea" | awk -F, '{print $2}')
    artista=$(echo "$linea" | awk -F, '{print $3}')
    fecha=$(date '+%F')
    hora=$(date '+%H:%M:%S')

    (
        flock -x 200
        id_cola=$(siguiente_id_cola)
        printf "%s,%s,%s,%s,%s,%s,%s,pendiente\n" "$id_cola" "$fecha" "$hora" "$USER" "$id" "$titulo" "$artista" >> "$COLA"
    ) 200>"$LOCK"

    echo "Solicitud registrada: $titulo - $artista"
    registrar_evento "INFO" "solicitó canción" "$titulo - $artista"
}

agregar_cancion() {
    local titulo artista album genero duracion nuevo_id

    read -rp "Título: " titulo
    read -rp "Artista: " artista
    read -rp "Álbum: " album
    read -rp "Género: " genero
    read -rp "Duración MM:SS: " duracion

    titulo=$(echo "$titulo" | tr ',' ' ')
    artista=$(echo "$artista" | tr ',' ' ')
    album=$(echo "$album" | tr ',' ' ')
    genero=$(echo "$genero" | tr ',' ' ')
    duracion=$(echo "$duracion" | tr ',' ' ')

    nuevo_id=$(tail -n +2 "$CATALOGO" | awk -F, 'NF {id=$1} END {print id+1}')

    if [[ -z "$nuevo_id" || "$nuevo_id" -eq 0 ]]; then
        nuevo_id=1
    fi

    printf "%s,%s,%s,%s,%s,%s,activo\n" "$nuevo_id" "$titulo" "$artista" "$album" "$genero" "$duracion" >> "$CATALOGO"

    echo "Canción agregada correctamente."
    registrar_evento "ADMIN" "agregó canción" "$titulo - $artista"
}

desactivar_cancion() {
    mostrar_catalogo
    echo
    read -rp "ID de la canción a desactivar: " id

    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "ID inválido."
        return
    fi

    if ! awk -F, -v id="$id" '$1 == id {found=1} END {exit !found}' "$CATALOGO"; then
        echo "No existe una canción con ese ID."
        return
    fi

    tmp=$(mktemp)
    awk -F, -v id="$id" 'BEGIN {OFS=","} NR==1 {print; next} $1==id {$7="inactivo"} {print}' "$CATALOGO" > "$tmp"
    cat "$tmp" > "$CATALOGO"
    rm -f "$tmp"

    echo "Canción desactivada."
    registrar_evento "ADMIN" "desactivó canción" "ID $id"
}

marcar_reproducida() {
    ver_cola
    echo
    read -rp "ID de cola a marcar como reproducida: " id_cola

    if ! [[ "$id_cola" =~ ^[0-9]+$ ]]; then
        echo "ID inválido."
        return
    fi

    if ! awk -F, -v id="$id_cola" '$1 == id {found=1} END {exit !found}' "$COLA"; then
        echo "No existe ese ID en la cola."
        return
    fi

    tmp=$(mktemp)
    awk -F, -v id="$id_cola" 'BEGIN {OFS=","} NR==1 {print; next} $1==id {$8="reproducida"} {print}' "$COLA" > "$tmp"
    cat "$tmp" > "$COLA"
    rm -f "$tmp"

    echo "Canción marcada como reproducida."
    registrar_evento "ADMIN" "marcó canción como reproducida" "ID cola $id_cola"
}

ver_logs() {
    if [[ ! -s "$LOG" ]]; then
        echo "La bitácora está vacía."
    else
        cat "$LOG"
    fi
}

ver_reportes() {
    echo "Reportes disponibles:"
    ls -1 "$REPORTS"
    echo
    read -rp "Nombre del reporte a ver: " archivo

    if [[ -f "$REPORTS/$archivo" ]]; then
        column -t -s, "$REPORTS/$archivo" 2>/dev/null || cat "$REPORTS/$archivo"
    else
        echo "No existe ese reporte."
    fi
}

eliminar_cancion() {
    mostrar_catalogo
    echo
    read -rp "ID de la canción a eliminar definitivamente: " id

    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "ID inválido."
        return
    fi

    local linea titulo artista tmp

    linea=$(awk -F, -v id="$id" '$1 == id {print; exit}' "$CATALOGO")

    if [[ -z "$linea" ]]; then
        echo "No existe una canción con ese ID."
        return
    fi

    titulo=$(echo "$linea" | awk -F, '{print $2}')
    artista=$(echo "$linea" | awk -F, '{print $3}')

    tmp=$(mktemp)

    awk -F, -v id="$id" 'BEGIN {OFS=","} $1 != id {print}' "$CATALOGO" > "$tmp"
    cat "$tmp" > "$CATALOGO"
    rm -f "$tmp"

    echo "Canción eliminada correctamente: $titulo - $artista"
    registrar_evento "ADMIN" "eliminó canción" "$titulo - $artista"
}

ver_letra_cancion() {
    mostrar_catalogo
    echo
    read -rp "Escribe el ID de la canción para ver su letra: " id

    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "ID inválido."
        return
    fi

    local linea titulo artista letra_archivo ruta_letra

    linea=$(awk -F, -v id="$id" '$1 == id {print; exit}' "$CATALOGO")

    if [[ -z "$linea" ]]; then
        echo "No existe una canción con ese ID."
        return
    fi

    titulo=$(echo "$linea" | awk -F, '{print $2}')
    artista=$(echo "$linea" | awk -F, '{print $3}')
    letra_archivo=$(echo "$linea" | awk -F, '{print $8}')
    ruta_letra="$BASE_DIR/$letra_archivo"

    if [[ ! -f "$ruta_letra" ]]; then
        echo "No hay letra registrada para esta canción."
        registrar_evento "INFO" "intentó ver letra no disponible" "$titulo - $artista"
        return
    fi

    echo "Letra: $titulo - $artista"
    echo "----------------------------------------"
    cat "$ruta_letra"

    registrar_evento "INFO" "consultó letra" "$titulo - $artista"
}

editar_letra_cancion() {
    mostrar_catalogo
    echo
    read -rp "ID de la canción cuya letra deseas editar: " id

    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "ID inválido."
        return
    fi

    local linea titulo artista letra_archivo ruta_letra

    linea=$(awk -F, -v id="$id" '$1 == id {print; exit}' "$CATALOGO")

    if [[ -z "$linea" ]]; then
        echo "No existe una canción con ese ID."
        return
    fi

    titulo=$(echo "$linea" | awk -F, '{print $2}')
    artista=$(echo "$linea" | awk -F, '{print $3}')
    letra_archivo=$(echo "$linea" | awk -F, '{print $8}')
    ruta_letra="$BASE_DIR/$letra_archivo"

    sudo nano "$ruta_letra"

    sudo chown root:karaoke_admins "$ruta_letra"
    sudo chmod 640 "$ruta_letra"
    sudo setfacl -m g:karaoke_users:r "$ruta_letra"

    echo "Letra actualizada: $titulo - $artista"
    registrar_evento "ADMIN" "editó letra" "$titulo - $artista"
}
