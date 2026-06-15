#!/bin/bash

source /srv/karaoke/lib/funciones.sh

mkdir -p "$REPORTS"

HISTORIAL="$BASE_DIR/playback/historial_reproduccion.csv"

{
    echo "titulo,artista,total"
    tail -n +2 "$COLA" | awk -F, 'NF>=8 {clave=$6","$7; conteo[clave]++} END {for (c in conteo) print c","conteo[c]}' | sort -t, -k3,3nr
} > "$REPORTS/reporte_canciones.csv"

{
    echo "usuario,total"
    tail -n +2 "$COLA" | awk -F, 'NF>=8 {conteo[$4]++} END {for (u in conteo) print u","conteo[u]}' | sort -t, -k2,2nr
} > "$REPORTS/reporte_usuarios.csv"

{
    echo "id_cola,fecha,hora,usuario,id_cancion,titulo,artista,estado"
    tail -n +2 "$COLA" | awk -F, '$8=="reproducida" {print}'
} > "$REPORTS/reporte_reproducidas.csv"

{
    echo "id,titulo,artista,archivo_letra,lineas,palabras,estado_letra"

    tail -n +2 "$CATALOGO" | while IFS=, read -r id titulo artista album genero duracion estado letra_archivo; do
        ruta="$BASE_DIR/$letra_archivo"

        if [[ -f "$ruta" ]]; then
            lineas=$(wc -l < "$ruta")
            palabras=$(wc -w < "$ruta")
            estado_letra="registrada"
        else
            lineas=0
            palabras=0
            estado_letra="sin_letra"
        fi

        echo "$id,$titulo,$artista,$letra_archivo,$lineas,$palabras,$estado_letra"
    done
} > "$REPORTS/reporte_letras.csv"

{
    echo "titulo,artista,reproducciones,tiempo_total_seg,tiempo_total_min"

    if [[ -f "$HISTORIAL" ]]; then
        tail -n +2 "$HISTORIAL" | awk -F, '
        NF>=11 {
            clave=$7","$8
            reproducciones[clave]++
            tiempo[clave]+=$10
        }
        END {
            for (c in reproducciones) {
                printf "%s,%d,%d,%.2f\n", c, reproducciones[c], tiempo[c], tiempo[c]/60
            }
        }' | sort -t, -k4,4nr
    fi
} > "$REPORTS/reporte_tiempo_reproduccion.csv"

{
    echo "Reporte general del sistema"
    echo "Fecha de generación: $(date '+%F %T')"
    echo
    echo "Total de canciones en catálogo: $(tail -n +2 "$CATALOGO" | wc -l)"
    echo "Total de solicitudes en cola: $(tail -n +2 "$COLA" | wc -l)"
    echo "Total de canciones reproducidas: $(tail -n +2 "$COLA" | awk -F, '$8=="reproducida" {c++} END {print c+0}')"
    echo "Total de eventos en bitácora: $(wc -l < "$LOG")"
    echo "Total de archivos de letras: $(find "$BASE_DIR/lyrics" -type f -name '*.txt' 2>/dev/null | wc -l)"
    echo "Total de palabras en letras: $(find "$BASE_DIR/lyrics" -type f -name '*.txt' -exec cat {} + 2>/dev/null | wc -w)"

    if [[ -f "$HISTORIAL" ]]; then
        echo "Total de reproducciones simuladas: $(tail -n +2 "$HISTORIAL" | wc -l)"
        echo "Tiempo total reproducido en segundos: $(tail -n +2 "$HISTORIAL" | awk -F, '{s+=$10} END {print s+0}')"
        echo "Tiempo total reproducido en minutos: $(tail -n +2 "$HISTORIAL" | awk -F, '{s+=$10} END {printf "%.2f", s/60}')"
    else
        echo "Total de reproducciones simuladas: 0"
        echo "Tiempo total reproducido en segundos: 0"
        echo "Tiempo total reproducido en minutos: 0.00"
    fi

    echo
    echo "Archivos generados:"
    echo "- reporte_canciones.csv"
    echo "- reporte_usuarios.csv"
    echo "- reporte_reproducidas.csv"
    echo "- reporte_letras.csv"
    echo "- reporte_tiempo_reproduccion.csv"
    echo "- reporte_general.txt"
} > "$REPORTS/reporte_general.txt"

chmod 660 "$REPORTS"/reporte_* 2>/dev/null

echo "Reportes generados correctamente en $REPORTS"
registrar_evento "ADMIN" "generó reportes" "$REPORTS"
