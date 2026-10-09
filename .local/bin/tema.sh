#!/usr/bin/env bash
# Cambia el rice entre "verde" (Verde Tech, el original) y "rojo" (demo Rojo Tech).
# Uso: tema.sh rojo   |   tema.sh verde
# La primera vez guarda una copia de los archivos verdes en ~/.local/share/temas/verde/

set -e
modo=${1:-}
[ "$modo" = rojo ] || [ "$modo" = verde ] || { echo "Uso: tema.sh rojo|verde"; exit 1; }

guardado=~/.local/share/temas/verde
archivos=(
  .config/alacritty/verdetech.toml
  .config/btop/themes/verdetech.theme
  .config/cava/config
  .config/fuzzel/fuzzel.ini
  .config/fastfetch/config.jsonc
  .config/quickshell/hud/Theme.qml
  .config/quickshell/hud/shell.qml
  .local/share/konsole/VerdeTech.colorscheme
)
fondo=~/Imágenes/wallpaper-cyber.png
fondo_rojo=~/Imágenes/wallpaper-cyber-rojo.png

# 1) Guardar el verde original (solo una vez)
if [ ! -d "$guardado" ]; then
  for f in "${archivos[@]}"; do
    [ -f ~/"$f" ] && install -D -m644 ~/"$f" "$guardado/$f"
  done
fi

# 2) Volver siempre a los archivos verdes originales
for f in "${archivos[@]}"; do
  [ -f "$guardado/$f" ] && cp "$guardado/$f" ~/"$f"
done

# Verde -> rojo (mismos tonos apagados, nada de neón)
hex=(
  6cc196:b3313a 8fd3ae:cc4a50 5fa8a0:9e3f2a 7fc2ba:b8563c 35706a:5e2418
  2f6b4e:6b1a1f 4f9a74:8f252c 2f4a3c:3f2224 cfdcd4:dccfd0 eef4f0:f4eeee
  7d9186:917d7f 4a5d52:5d4a4c 3a4a41:4a3a3c 2b3d33:3d2b2d 1f2f27:2f1f21
  1a2520:251a1b 0d1310:120a0b 0a0f0c:0f0a0b
)
rgb=(
  108,193,150:179,49,58 143,211,174:204,74,80 95,168,160:158,63,42
  63,122,92:107,26,31 207,220,212:220,207,208 19,27,23:27,19,20
  125,145,134:145,125,127 13,19,16:18,10,11 238,244,240:244,238,238
  26,37,32:37,26,27 58,74,65:74,58,60 36,48,41:48,36,38
)
pintar_rojo() {  # archivo
  local args=() p de a
  for p in "${hex[@]}"; do args+=(-e "s/${p%%:*}/${p##*:}/Ig"); done
  for p in "${rgb[@]}"; do
    args+=(-e "s/\b${p%%:*}\b/${p##*:}/g")
    de=${p%%:*}; a=${p##*:}
    args+=(-e "s/\b${de//,/;}\b/${a//,/;}/g")   # formato 108;193;150 (fastfetch)
  done
  sed -i "${args[@]}" "$1"
}

if [ "$modo" = rojo ]; then
  for f in "${archivos[@]}"; do [ -f ~/"$f" ] && pintar_rojo ~/"$f"; done
  cp ~/.local/share/color-schemes/VerdeTech.colors ~/.local/share/color-schemes/RojoTech.colors
  pintar_rojo ~/.local/share/color-schemes/RojoTech.colors
  sed -i -e "s/^Name=.*/Name=Rojo Tech/" -e "s/^ColorScheme=.*/ColorScheme=RojoTech/" ~/.local/share/color-schemes/RojoTech.colors
  esquema=RojoTech; borde1=179,49,58; borde2=158,63,42
  # Fondo: girar el tono del verde al rojo
  [ -f "$fondo_rojo" ] || magick "$fondo" -modulate 80,115,13 "$fondo_rojo"
  imagen=$fondo_rojo
else
  esquema=VerdeTech; borde1=108,193,150; borde2=95,168,160
  imagen=$fondo
fi

# 3) Aplicar
plasma-apply-colorscheme "$esquema" >/dev/null
kwriteconfig6 --file kwinrc --group Round-Corners --key ActiveOutlineColor "$borde1"
kwriteconfig6 --file kwinrc --group Round-Corners --key ActiveOutlineColor2 "$borde2"
qdbus6 org.kde.KWin /KWin reconfigure
plasma-apply-wallpaperimage "$imagen" >/dev/null
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$imagen"

# HUD de Quickshell: reiniciar para que lea los colores nuevos
if pgrep -x qs >/dev/null || pgrep -f '^qs -c hud' >/dev/null; then
  pkill -f '^qs -c hud'; sleep 0.5; setsid -f qs -c hud >/dev/null 2>&1
fi
# btop y cava leen el tema al arrancar: se ven con el color nuevo al reabrirlos
echo "Tema $modo aplicado."
