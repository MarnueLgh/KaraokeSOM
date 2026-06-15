#!/bin/bash

source /srv/karaoke/lib/funciones.sh

cleanup_terminal() {
    clear
    stty sane 2>/dev/null
}

trap cleanup_terminal EXIT INT TERM

azul="\033[38;5;75m"
gris="\033[38;5;245m"
blanco="\033[97m"
amarillo="\033[38;5;214m"
reset_color="\033[0m"

dibujar_header() {
    clear
    echo
    echo -e "${gris}        ██╗  ██╗ █████╗ ██████╗  █████╗  ██████╗ ██╗  ██╗███████╗${reset_color}"
    echo -e "${gris}        ██║ ██╔╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║ ██╔╝██╔════╝${reset_color}"
    echo -e "${blanco}        █████╔╝ ███████║██████╔╝███████║██║   ██║█████╔╝ █████╗  ${reset_color}"
    echo -e "${blanco}        ██╔═██╗ ██╔══██║██╔══██╗██╔══██║██║   ██║██╔═██╗ ██╔══╝  ${reset_color}"
    echo -e "${blanco}        ██║  ██╗██║  ██║██║  ██║██║  ██║╚██████╔╝██║  ██╗███████╗${reset_color}"
    echo -e "${blanco}        ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝${reset_color}"
    echo
    echo -e "                      ${azul}Administrador${reset_color}"
    echo
    echo -e "${gris}     ┌────────────────────────────────────────────────────────────┐${reset_color}"
}

dibujar_footer() {
    echo -e "${gris}     └────────────────────────────────────────────────────────────┘${reset_color}"
    echo
    echo -e "        ${amarillo}Tip:${reset_color} escribe el número de la opción y presiona ENTER"
    echo
}

menu_admin() {
    dibujar_header
    echo -e "${gris}     │${reset_color} ${azul}1${reset_color}. Ver catálogo                                            ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}2${reset_color}. Buscar canción                                          ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}3${reset_color}. Agregar canción                                         ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}4${reset_color}. Desactivar canción                                      ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}5${reset_color}. Eliminar canción                                        ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}6${reset_color}. Ver letra de canción                                    ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}7${reset_color}. Editar letra de canción                                 ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}8${reset_color}. Ver cola                                                ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}9${reset_color}. Marcar canción como reproducida                         ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}10${reset_color}. Generar reportes                                       ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}11${reset_color}. Ver reportes existentes                                ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}12${reset_color}. Ver bitácoras                                          ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color} ${azul}13${reset_color}. Salir                                                  ${gris}│${reset_color}"
    dibujar_footer
    read -rp "        Selecciona una opción: " opcion
}

while true; do
    menu_admin
    clear

    case "$opcion" in
        1)
            mostrar_catalogo
            pausa
            ;;
        2)
            buscar_cancion
            pausa
            ;;
        3)
            agregar_cancion
            pausa
            ;;
        4)
            desactivar_cancion
            pausa
            ;;
        5)
            eliminar_cancion
            pausa
            ;;
        6)
            ver_letra_cancion
            pausa
            ;;
        7)
            editar_letra_cancion
            pausa
            ;;
        8)
            ver_cola
            pausa
            ;;
        9)
            marcar_reproducida
            pausa
            ;;
        10)
            /srv/karaoke/bin/generar_reportes.sh
            pausa
            ;;
        11)
            ver_reportes
            pausa
            ;;
        12)
            ver_logs
            pausa
            ;;
        13|q|Q)
            registrar_evento "ADMIN" "salió del panel administrativo" "-"
            cleanup_terminal
            exit 0
            ;;
        *)
            echo "Opción inválida."
            pausa
            ;;
    esac
done
