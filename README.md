# Proyecto Karaoke Multiusuario con TUI

Sistema de karaoke multiusuario ejecutado en Ubuntu Server.

## Características

- Acceso por SSH.
- Usuarios y grupos con roles diferenciados.
- Interfaz TUI en Bash.
- Catálogo de canciones en CSV.
- Letras almacenadas en archivos TXT.
- Cola de reproducción protegida con flock.
- Bitácoras de actividad.
- Reportes generados automáticamente.
- Automatización con cron.

## Usuarios del sistema

- naur: administrador.
- trebor: usuario normal.
- luas: usuario normal.
- ankira: usuario normal.

## Comando principal

karaoke

## Estructura principal

/srv/karaoke/
├── bin/
├── lib/
├── data/
├── lyrics/
├── queue/
├── logs/
├── locks/
└── reports/
