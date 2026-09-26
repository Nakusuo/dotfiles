#!/usr/bin/env bash
# Dashboard Verde Tech: 4 Alacritty en mosaico (Krohnkite) en el escritorio 1.
# El verde de los programas es el "color 2" del tema de Alacritty (#6cc196).

# Al iniciar sesión, esperar a que KWin, la actividad y Krohnkite estén listos (máx ~20 s)
for _ in $(seq 40); do
  [ "$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded krohnkite 2>/dev/null)" = true ] &&
  [ -n "$(qdbus6 org.kde.ActivityManager /ActivityManager/Activities CurrentActivity 2>/dev/null)" ] && break
  sleep 0.5
done
sleep 2   # margen para que Krohnkite termine de arrancar

qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop "${DASH_DESKTOP:-1}" >/dev/null
sleep 0.3

# Si algún programa no está instalado, usa otro que sí esté
reloj='tty-clock -c -C 2 -b -s -D'
command -v tty-clock >/dev/null || reloj='watch -t -n1 date +%H:%M:%S'
pipes='pipes.sh -c 2 -c 6 -t 1 -R'
command -v pipes.sh >/dev/null || pipes='cava'

lanzar() {  # clase comando...
  local clase=$1; shift
  # letra algo más pequeña para que btop quepa; "negro" = fondo para que cmatrix no pinte bloques
  alacritty --class "$clase" -o font.size=9 -o 'colors.normal.black="0x0d1310"' -e sh -c "$*" &
  sleep 0.6   # pausa para que el orden del mosaico sea siempre el mismo
}

# Cuenta las ventanas del dashboard que quedaron sueltas (tamaño por defecto 800x600 = sin mosaico)
sueltas() {
  local js marca; js=$(mktemp --suffix=.js); marca="DASHCHK$$$RANDOM"
  echo "print('$marca ' + workspace.windowList().filter(w => w.resourceClass.startsWith('dash-') && w.frameGeometry.width == 800 && w.frameGeometry.height == 600).length);" > "$js"
  local id; id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$js" "$marca")
  qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run >/dev/null
  sleep 0.5
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$marca" >/dev/null
  rm -f "$js"
  journalctl --user --since "-1min" -o cat | grep "$marca" | tail -1 | awk '{print $2}'
}

abrir_todo() {
  # La primera ventana ocupa el hueco grande (maestro) de Krohnkite
  # btop espera a que estén las 4 ventanas y, si su hueco es pequeño, usa el modo compacto (CPU + red)
  lanzar dash-btop   'sleep 2.5; [ $(tput lines) -ge 24 ] && [ $(tput cols) -ge 80 ] && exec btop || exec btop -p 3'
  lanzar dash-reloj  "$reloj"
  lanzar dash-matrix 'cmatrix -C green -b -u 5'
  lanzar dash-pipes  "$pipes"
}

# Abrir y comprobar; si Krohnkite dejó ventanas sueltas, cerrar y reintentar (hasta 3 veces)
for intento in 1 2 3; do
  abrir_todo
  sleep 1.5
  [ "$(sueltas)" = 0 ] && break
  pkill -f '^alacritty --class dash-'
  sleep 2
done
