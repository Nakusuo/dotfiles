#!/usr/bin/env bash
# Prepara un GIF o video para la pantalla de bloqueo.
# Lo pasa a MP4 del tamaño de la pantalla: un GIF lo decodifica la CPU cuadro
# por cuadro, un MP4 lo decodifica la tarjeta de video (mucho más liviano).
# Uso: bloqueo-video.sh archivo.gif|archivo.mp4
set -e
[ -f "${1:-}" ] || { echo "Uso: bloqueo-video.sh archivo.gif|archivo.mp4"; exit 1; }
command -v ffmpeg >/dev/null || { echo "Falta ffmpeg: sudo pacman -S ffmpeg"; exit 1; }

# tamaño de la pantalla principal (1366x768 si no se puede leer)
tam=$(kscreen-doctor -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -oE '[0-9]+x[0-9]+@' | head -1 | tr -d @)
ancho=${tam%x*}; alto=${tam#*x}
[ -n "$ancho" ] && [ -n "$alto" ] || { ancho=1366; alto=768; }

videos=$(xdg-user-dir VIDEOS 2>/dev/null || echo ~/Vídeos)
mkdir -p "$videos"
salida=$videos/bloqueo.mp4
ffmpeg -loglevel error -y -i "$1" \
  -vf "scale=${ancho}:${alto}:force_original_aspect_ratio=increase,crop=${ancho}:${alto},fps=30" \
  -c:v libx264 -crf 22 -preset slow -pix_fmt yuv420p -movflags +faststart -an "$salida"
echo "Listo: $salida (${ancho}x${alto})"

if [ ! -d /usr/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn ] &&
   [ ! -d ~/.local/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn ]; then
  echo "Falta el plugin de video: paru -S plasma6-wallpapers-smart-video-wallpaper-reborn"
fi
echo "Ahora: Preferencias del sistema → Bloqueo de pantalla → Configurar apariencia →"
echo "  Tipo de fondo «Smart Video Wallpaper Reborn» → añade $salida"
