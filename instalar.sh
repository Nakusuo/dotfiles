#!/usr/bin/env bash
# Copia esta configuración al sistema. Antes guarda lo que había en ~/dotfiles-respaldo-FECHA
cd "$(dirname "$0")"
respaldo=~/dotfiles-respaldo-$(date +%F-%H%M)
while IFS= read -r f; do
  [ -e ~/"$f" ] && { mkdir -p "$respaldo/$(dirname "$f")"; cp ~/"$f" "$respaldo/$f"; }
  mkdir -p ~/"$(dirname "$f")"; cp "$f" ~/"$f"
done < archivos.txt
chmod +x ~/.local/bin/dashboard.sh ~/.local/bin/tema.sh ~/.local/bin/ligero.sh
# El dashboard ya no arranca solo al iniciar sesión (4 terminales animadas gastan mucho); se abre con Super+Shift+M
rm -f ~/.config/autostart/dashboard.desktop
echo "Listo. Lo anterior quedó en $respaldo. Cierra sesión y vuelve a entrar."
