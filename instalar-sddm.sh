#!/usr/bin/env bash
# Instala el login Verde Tech NVG en SDDM (pide sudo). Con --quitar vuelve al tema anterior.
# Probar sin cerrar sesión: sddm-greeter-qt6 --test-mode --theme sddm/verdetech
cd "$(dirname "$0")"
destino=/usr/share/sddm/themes/verdetech
conf=/etc/sddm.conf.d/verdetech.conf

if [ "$1" = "--quitar" ]; then
  sudo rm -rf "$destino" "$conf"
  echo "Quitado: SDDM vuelve al tema que tenía."
  exit
fi

[ -f sddm/verdetech/fondo.png ] || cp "Imágenes/fondo-y2k.png" sddm/verdetech/fondo.png
sudo mkdir -p "$destino" /etc/sddm.conf.d
sudo cp sddm/verdetech/* "$destino/"
printf '[Theme]\nCurrent=verdetech\n' | sudo tee "$conf" >/dev/null
echo "Listo: el login sale con el tema Verde Tech NVG la próxima vez que entres."
