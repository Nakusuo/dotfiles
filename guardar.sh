#!/usr/bin/env bash
# Copia la configuración actual del sistema a esta carpeta y la sube a GitHub.
cd "$(dirname "$0")"
while IFS= read -r f; do
  [ -e ~/"$f" ] && { mkdir -p "$(dirname "$f")"; cp ~/"$f" "$f"; }
done < archivos.txt
git add -A
git commit -m "Actualizar configuración $(date +%F)" && git push
