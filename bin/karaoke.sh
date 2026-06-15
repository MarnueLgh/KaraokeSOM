#!/bin/bash

if id -nG "$USER" | grep -qw "karaoke_admins"; then
    exec /srv/karaoke/bin/admin_tui.sh
elif id -nG "$USER" | grep -qw "karaoke_users"; then
    exec /srv/karaoke/bin/usuario_tui.sh
else
    echo "No tienes permisos para usar el sistema de karaoke."
    exit 1
fi
