#!/usr/bin/env bash
# Escritorio Verde Tech NVG (Quickshell): barra lateral, panel, lanzador, notificaciones y OSD.
# Uso: escritorio.sh on|off
#   on:  quita el panel de arriba de Plasma (así deja libres las notificaciones), apaga el OSD de Plasma
#        y arranca «qs -c escritorio» (también al iniciar sesión)
#   off: lo deja todo como estaba
datos=~/.local/share/escritorio
auto=~/.config/autostart/quickshell-escritorio.desktop
qsdir=~/.config/quickshell/escritorio
plasma() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }

case ${1:-on} in
on)
  mkdir -p ~/.cache/escritorio "$qsdir/services"
  # la paleta y los servicios son los del HUD: así tema.sh cambia verde/rojo en todo a la vez
  ln -sfn ../hud/Theme.qml "$qsdir/Theme.qml"
  ln -sfn ../hud/cava.conf "$qsdir/cava.conf"
  ln -sfn ../../hud/services/SysStats.qml "$qsdir/services/SysStats.qml"
  ln -sfn ../../hud/services/Cava.qml "$qsdir/services/Cava.qml"

  if [ ! -s "$datos/panel.json" ]; then
    # guarda qué tenía el panel de arriba (para «off») y lo quita
    plasma 'var r=[];panels().forEach(function(p){if(p.location=="top"){r.push({h:p.height,w:p.widgets().map(function(w){return w.type})});p.remove()}});print(JSON.stringify(r))' > "$datos/panel.json"
  fi
  kwriteconfig6 --file plasmarc --group OSD --key Enabled false
  cp "$datos/quickshell-escritorio.desktop" "$auto"
  kbuildsycoca6 >/dev/null 2>&1   # registra los atajos Super+D y Super+S

  pkill -f 'qs -c escritorio' ; sleep 0.5
  setsid qs -c escritorio >/dev/null 2>&1 &
  sleep 2
  if ! qdbus6 org.freedesktop.Notifications >/dev/null 2>&1 ||
     qdbus6 org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.GetConnectionUnixProcessID org.freedesktop.Notifications 2>/dev/null |
       xargs -r ps -o comm= -p | grep -q plasmashell; then
    echo "Ojo: Plasma sigue con las notificaciones. Quita el applet «Notificaciones» y vuelve a ejecutar esto."
  fi
  echo "Listo. Super+D lanzador · Super+S panel · ● REC en la barra. Para volver: escritorio.sh off"
  ;;
off)
  pkill -f 'qs -c escritorio'
  rm -f "$auto"
  kwriteconfig6 --file plasmarc --group OSD --key Enabled true
  if [ -s "$datos/panel.json" ]; then
    plasma "var d=$(cat "$datos/panel.json");d.forEach(function(x){var p=new Panel;p.location='top';p.height=x.h;x.w.forEach(function(t){p.addWidget(t)})})"
    rm -f "$datos/panel.json"
  fi
  echo "Plasma vuelve a ser el de antes (para la configuración exacta del panel: instalar.sh)"
  ;;
*) echo "Uso: escritorio.sh on|off"; exit 1 ;;
esac
