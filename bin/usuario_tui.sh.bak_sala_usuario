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
    echo -e "                         ${azul}Usuario${reset_color}"
    echo
    echo -e "${gris}     ┌────────────────────────────────────────────────────────────┐${reset_color}"
}

dibujar_footer() {
    echo -e "${gris}     └────────────────────────────────────────────────────────────┘${reset_color}"
    echo
    echo -e "        ${amarillo}Tip:${reset_color} escribe el número de la opción y presiona ENTER"
    echo
}

menu_usuario() {
    dibujar_header
    echo -e "${gris}     │${reset_color}  ${azul}1${reset_color}. Ver catálogo completo                                  ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color}  ${azul}2${reset_color}. Buscar canción                                         ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color}  ${azul}3${reset_color}. Solicitar canción                                      ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color}  ${azul}4${reset_color}. Ver cola de reproducción                               ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color}  ${azul}5${reset_color}. Ver letra de canción                                   ${gris}│${reset_color}"
    echo -e "${gris}     │${reset_color}  ${azul}6${reset_color}. Salir                                                  ${gris}│${reset_color}"
    dibujar_footer
    read -rp "        Selecciona una opción: " opcion
}

while true; do
    menu_usuario
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
            solicitar_cancion
            pausa
            ;;
        4)
            ver_cola
            pausa
            ;;
        5)
            ver_letra_cancion
            pausa
            ;;
        6|q|Q)
            registrar_evento "INFO" "salió del sistema" "-"
            cleanup_terminal
            exit 0
            ;;
    esac
done
