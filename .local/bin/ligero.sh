#!/usr/bin/env bash
# Modo ligero (como el "game mode" de otros rices): apaga el blur, las sombras
# y las animaciones de KWin para que la laptop vaya suelta. Otra vez lo devuelve.
# Uso: ligero.sh [on|off]   (sin nada, alterna)   — atajo: Super+Shift+G
estado=~/.cache/modo-ligero
modo=${1:-$([ -f "$estado" ] && echo off || echo on)}

kw() { kwriteconfig6 --file kwinrc --group "$1" --key "$2" "$3"; }
efecto() {  # load|unload nombre
  qdbus6 org.kde.KWin /Effects "org.kde.kwin.Effects.${1}Effect" "$2" >/dev/null 2>&1
}

if [ "$modo" = on ]; then
  touch "$estado"
  kw Plugins glassEnabled false;  efecto unload glass
  kw Plugins slideEnabled false;  efecto unload slide
  kw Plugins scaleEnabled false;  efecto unload scale
  kw Round-Corners ActiveShadowSize 0
  kw Round-Corners InactiveShadowSize 0
  kwriteconfig6 --notify --file kdeglobals --group KDE --key AnimationDurationFactor 0
  aviso="Modo ligero: sin blur, sombras ni animaciones"
else
  rm -f "$estado"
  kw Plugins glassEnabled true;   efecto load glass
  kw Plugins slideEnabled true;   efecto load slide
  kw Plugins scaleEnabled true;   efecto load scale
  kw Round-Corners ActiveShadowSize 20
  kw Round-Corners InactiveShadowSize 12
  kwriteconfig6 --notify --file kdeglobals --group KDE --key AnimationDurationFactor 0.5
  aviso="Modo normal: Verde Tech completo"
fi

qdbus6 org.kde.KWin /KWin reconfigure >/dev/null
command -v notify-send >/dev/null && notify-send -a "Verde Tech" -i preferences-desktop-effects "$aviso"
