#!/usr/bin/env bash
# Pasa varias fotos por fondo-y2k.py y las pone como fondo que se alterna
# (presentación de Plasma). Acepta rutas o enlaces.
# Uso: fondos-y2k.sh [-m minutos] foto1 foto2 ...      (por defecto cada 10 min)
# Las opciones de fondo-y2k.py (--ascii, --errores, --sin-osd) van al final y valen para todas.
set -e
min=10
[ "${1:-}" = -m ] && { min=$2; shift 2; }
fotos=(); extra=()
for a in "$@"; do [[ $a == --* ]] && extra+=("$a") || fotos+=("$a"); done
[ ${#fotos[@]} -ge 1 ] || { echo "Uso: fondos-y2k.sh [-m minutos] foto1 foto2 ... [--sin-osd]"; exit 1; }

carpeta=$(xdg-user-dir PICTURES 2>/dev/null || echo ~/Imágenes)/fondos-y2k
mkdir -p "$carpeta"
rm -f "$carpeta"/*.png               # solo quedan las de esta vez
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

i=0
for f in "${fotos[@]}"; do
  i=$((i + 1))
  if [[ $f == http* ]]; then curl -fsSL -o "$tmp/$i" "$f"; f=$tmp/$i; fi
  ~/.local/bin/fondo-y2k.py "$f" "$carpeta/$(printf %02d $i).png" "${extra[@]}"
done

# Presentación en todos los escritorios: cambia cada $min minutos
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
for (const d of desktops()) {
  d.wallpaperPlugin = 'org.kde.slideshow';
  d.currentConfigGroup = ['Wallpaper', 'org.kde.slideshow', 'General'];
  d.writeConfig('SlidePaths', ['$carpeta']);
  d.writeConfig('SlideInterval', $((min * 60)));
  d.reloadConfig();
}" >/dev/null
echo "Listo: $i fondos en $carpeta, cambian cada $min min."
