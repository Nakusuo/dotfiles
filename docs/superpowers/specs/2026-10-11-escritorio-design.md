# Escritorio Verde Tech NVG — diseño

Fecha: 2026-10-11 · Estado: aprobado en chat

## Objetivo

Que el escritorio de KDE Plasma se sienta como los rices de Caelestia Shell
(barra propia, panel desplegable, lanzador, notificaciones y login a medida),
pero con la estética de la casa: pantalla de videocámara de visión nocturna
del 2000. Verde fósforo, scanlines, ventanas Win98 con bisel y REC en rojo
como único color de alarma.

Se queda en **KDE Plasma 6** (no Hyprland). El HUD y el dock actuales no se tocan.

## Regla número uno: laptop vieja

Todo corre en una laptop viejita con pantalla de 1366×768. Si una idea choca
con esto, gana el rendimiento.

- Sin blur, sombras, shaders, `MultiEffect` ni `layer.enabled` en lo nuevo.
- Nada mide, sondea ni anima mientras no está a la vista. Los servicios se
  activan al abrir su panel y se apagan al cerrarlo (como `SysStats.active` del HUD).
- Timers lentos. Reloj de la barra: 1 por minuto. Clima: cada 30 min, con caché en disco.
  Parpadeo de REC: un `Timer` de 1 s que cambia la opacidad (en modo ligero, fijo).
- Las animaciones duran como mucho 220 ms, solo animan `x`/`y`/`opacity` y nunca se repiten en bucle.
- Máximo 3 notificaciones visibles a la vez. El resto espera en cola.
- Las ventanas emergentes (panel, lanzador, menú de apagado) se crean al abrirse
  (`LazyLoader`) y se destruyen al cerrarse, para no ocupar memoria en reposo.
- Meta: `escritorio` en reposo por debajo de unos 80 MB de RSS y sin CPU apreciable
  (medido con `btop` en la laptop).

## Base común

- Nuevo config de Quickshell: `.config/quickshell/escritorio/` con su `shell.qml`.
- `escritorio/Theme.qml` es un **enlace simbólico** a `../hud/Theme.qml`. Una sola
  paleta, y `tema.sh` cambia entre verde y rojo en todo a la vez.
- Los servicios se comparten con enlaces simbólicos: `services/SysStats.qml` y
  `services/Cava.qml` apuntan a los del HUD. Los componentes del HUD no se
  reutilizan: `MusicPanel` usa `QtQuick.Effects` y está pensado para su tamaño.
- Componentes propios de `escritorio/components/`:
  - `VentanaW98.qml`: marco con bisel de 2 px, barra de título en degradado
    `tituloA→tituloB`, variante roja (`alerta`) y botón ×. Lo usan el panel, el
    lanzador, las notificaciones y el menú de apagado.
  - `TextoNvg.qml`: el texto lima `#b6f06a` con contorno, como el OSD del HUD.
- **IPC** (`IpcHandler`, target `escritorio`): `panel`, `lanzador`, `ligero on|off`.
  Los atajos de KDE llaman a `qs ipc -c escritorio call escritorio <función>`.
- **Modo ligero:** `ligero.sh` llama a `ligero on|off`. Al arrancar, `escritorio`
  lee `~/.cache/modo-ligero`. En modo ligero no hay animaciones, ni barrido de
  scanlines, ni parpadeo.
- **`escritorio.sh on|off`** (en `.local/bin/`):
  - `on`: activa el autostart, quita el panel superior de Plasma con
    `qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript`, pone
    `plasmarc [OSD] Enabled=false`, cambia el atajo de fuzzel por el lanzador,
    añade Super+D y arranca `qs -c escritorio`.
  - `off`: lo deshace todo. Antes de quitar el panel guarda su configuración en
    `~/.local/share/escritorio/panel.js` para poder volver a crearlo.

## 1. Barra lateral

- `PanelWindow` anclada a la izquierda, 44 px de ancho y de alto completo.
  `exclusiveZone: 44` para que las ventanas no se metan debajo.
  Capa `Top`, namespace `verdetech-barra`.
- De arriba abajo:
  1. **● REC** en rojo, parpadeando. Un clic abre o cierra el panel desplegable.
  2. **Escritorios virtuales:** cuadritos `01`–`04`. El activo va relleno de lima,
     los ocupados con borde y los vacíos tenues. Un clic cambia de escritorio.
     Los datos salen de KWin por D-Bus (`org.kde.KWin /VirtualDesktopManager`):
     un `Process` con `dbus-monitor` escucha los cambios, sin sondear.
  3. **Reloj vertical:** hora y minutos en dos líneas, y debajo `11·10` en pequeño.
  4. **Bandeja:** `Quickshell.Services.SystemTray`, con iconos en monocromo verde.
     El clic izquierdo activa la app y el derecho abre su menú.
  5. **Estado:**
     - volumen con `Quickshell.Services.Pipewire` (la rueda del ratón lo cambia);
     - red con `nmcli monitor`, mostrando ícono y potencia en barritas;
     - batería con `UPower`, en rojo por debajo del 15 %.
  6. **⏻ Apagado:** `VentanaW98` con Bloquear (`loginctl lock-session`),
     Cerrar sesión, Reiniciar y Apagar (con `qdbus6 org.kde.LogoutPrompt`, o
     `systemctl` si falla).
- La barra es de color `bg` con 92 % de opacidad. Sin blur.

## 2. Panel desplegable

- Se abre con un clic en ● REC o con **Super+D** (IPC `panel`). Es una `PanelWindow`
  pegada a la derecha de la barra, de 420 px de ancho y alto completo.
  `exclusiveZone: 0` y teclado `OnDemand`, para que Esc la cierre.
- Al abrir se desliza de `x = -420` a `0` en 220 ms y una línea de scanline recorre
  el panel una sola vez. En modo ligero aparece de golpe.
- Arriba lleva el `TextoNvg` `Standard NVG · 40° FOV` y el contador REC desde que se abrió.
- Dentro, ventanas `VentanaW98` en columna:
  - **MÚSICA.EXE:** `Musica.qml` propio y ligero: MPRIS (título, artista, barra de
    progreso, ⏮ ⏯ ⏭) y 16 barras de cava solo mientras suena y el panel está abierto.
  - **CALENDARIO:** el mes en una cuadrícula de 7 columnas, con hoy relleno de lima.
    Con flechas se cambia de mes.
  - **CLIMA:** `curl wttr.in/?format=j1` cada 30 minutos, guardado en
    `~/.cache/escritorio/clima.json`. Muestra temperatura, estado y la mínima y
    máxima de hoy. Sin red, `NO SIGNAL` con el último dato y su hora.
  - **SISTEMA:** medidores de CPU, RAM y batería con `SysStats` (`active` solo
    con el panel abierto) y el tiempo encendido.
  - **AVISOS:** las últimas 10 notificaciones de la sesión (en memoria, no en
    disco), con el botón «Borrar».
- Se cierra con Esc, con un clic fuera (una `PanelWindow` transparente
  detrás del panel recoge ese clic) o con otro clic en ● REC.

## 3. Lanzador

- Se abre con **Alt+Espacio** (IPC `lanzador`) y sustituye al atajo de fuzzel.
  Es una `VentanaW98` centrada, de 520 px de ancho, con título `EJECUTAR`.
- Tiene un campo `C:\> ` con cursor de bloque parpadeante (en modo ligero, fijo).
- Busca en `DesktopEntries.applications`, filtrando las entradas `NoDisplay`.
  Las coincidencias que empiezan con el texto van primero y luego las que lo
  contienen. Sin búsqueda difusa pesada.
- Muestra hasta 8 resultados con icono y nombre. El elegido va con `▶` y fondo lima tenue.
- Teclas: ↑/↓ para moverse, Enter para abrir (`entry.execute()`) y Esc para cerrar.
  Con el texto vacío salen las 8 apps abiertas más recientemente, guardadas en
  `~/.cache/escritorio/recientes.json`.

## 4. Notificaciones y OSD

- **Notificaciones:** `Quickshell.Services.Notifications.NotificationServer`
  (con `actionsSupported` y `imageSupported`).
  - Son `VentanaW98` de 340 px apiladas arriba a la derecha, como mucho 3 a la vez.
  - Normales: barra de título verde, se cierran a los 5 s (o al tiempo que pida la app).
  - Urgencia `Critical`: barra roja con **警告**, no se cierran solas.
  - Un clic ejecuta la acción `default`. Los botones de acción salen como botones Win98.
  - Cada notificación se añade a AVISOS del panel.
- Solo un programa puede recibir notificaciones. Al quitar el panel de Plasma
  (con su bandeja) se libera el servicio. **A comprobar en la laptop:** si
  `plasmashell` lo sigue reteniendo, `escritorio.sh on` lo indicará y habrá que
  quitar el applet de notificaciones a mano.
- **OSD:**
  - Volumen: `Pipewire.defaultAudioSink.audio.volume` y `muted` (enlace, sin sondear).
  - Brillo: `FileView` con `watchChanges` sobre `/sys/class/backlight/*/brightness`.
  - Abajo al centro, en `TextoNvg`: `VOL ▮▮▮▮▮▮▯▯▯▯ 60%` o `BRI …`, y `MUTE` en rojo.
    Se oculta a los 1,5 s.
  - El de Plasma se apaga con `plasmarc [OSD] Enabled=false` (desde `escritorio.sh on`).

## 5. Login (SDDM)

- Tema aparte en el repo: `sddm/verdetech/` con `Main.qml`, `metadata.desktop`,
  `theme.conf` y `fondo.png`, que es una copia de `Imágenes/fondo-y2k.png`.
  Usa QtQuick 6 (el greeter Qt6 de SDDM en Plasma 6). Sin efectos.
- `instalar-sddm.sh` (pide `sudo`):
  - copia el tema a `/usr/share/sddm/themes/verdetech`;
  - escribe `/etc/sddm.conf.d/verdetech.conf` con `[Theme] Current=verdetech`;
  - con `--quitar`, vuelve al tema anterior.
- Pantalla:
  - el fondo a tamaño completo;
  - en las esquinas, los textos de cámara: Standard NVG/40° FOV, ALT, la fecha y
    `● REC hh:mm:ss`;
  - al centro, una ventana Win98 «INICIAR SESIÓN» con usuario (lista de
    `userModel`, o texto), contraseña, selector de sesión (`sessionModel`) y los
    botones Entrar, Reiniciar y Apagar.
- Si falla `sddm.loginFailed`, la ventana tiembla (6 pasos, 300 ms) y aparece una
  ventanita roja **警告 ACCESO DENEGADO**. La contraseña se borra y el foco vuelve a ella.
- Se prueba sin cerrar sesión con `sddm-greeter-qt6 --test-mode --theme sddm/verdetech`.

## Instalación y repo

- `archivos.txt`: todo lo de `.config/quickshell/escritorio/`, `escritorio.sh`
  y el autostart `.config/autostart/quickshell-escritorio.desktop`.
- `instalar.sh`: `chmod +x` de los scripts nuevos. No activa nada por su cuenta;
  al final dice «Ejecuta `escritorio.sh on`».
- `README.md`: una sección «Escritorio» con los atajos y cómo volver atrás.

## Fuera de alcance

La pantalla de bloqueo (ya está tematizada), Hyprland, calculadora o búsqueda de
archivos en el lanzador, historial de notificaciones en disco y soporte para
varios monitores (por ahora solo la pantalla principal).

## Pruebas

Se edita desde Windows, sin Quickshell. Cada pieza se prueba en la laptop:

- `qs -c escritorio` sin errores en la terminal.
- Una lista corta de comprobaciones por pieza (abrir/cerrar, atajos, modo ligero,
  tema rojo, `btop` en reposo).
- `escritorio.sh off` deja Plasma como estaba.

## Orden de implementación

1. Base común y barra lateral, con `escritorio.sh`.
2. Panel desplegable.
3. Lanzador.
4. Notificaciones y OSD.
5. Login (SDDM).

Cada paso termina instalable y con su lista de pruebas.
