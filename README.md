# Dotfiles — KDE Plasma "Verde Tech"

Mi rice de KDE Plasma 6 (CachyOS, Wayland) con aspecto tipo Hyprland: paleta verde apagada, ventanas en mosaico y un dashboard de terminales.

![Fondo](Imágenes/wallpaper-tech.png)

## Qué incluye

- **Colores:** esquema `VerdeTech` (y la demo `RojoTech`) para KDE, Konsole, Alacritty, btop, cava, fastfetch y fuzzel.
- **Mosaico:** Krohnkite con huecos de 10 px, esquinas redondeadas y 5 escritorios.
- **Dashboard:** `dashboard.sh` abre btop, reloj, cmatrix y pipes en mosaico al iniciar sesión (Super+Shift+M).
- **Cambio de tema:** `tema.sh verde` o `tema.sh rojo`.
- **Dock (Quickshell):** efecto lupa estilo Mac, se esconde cuando una ventana lo tapa. Ver abajo.
- **HUD (Super+A):** reloj reactor, sistema y música sobre una lluvia tipo cmatrix, con el mismo estilo que el dashboard. Esc o clic para cerrar.

## HUD

![HUD](docs/hud.png)

## Dock

![Dock](docs/dock.png)

Dock propio hecho con Quickshell en `.config/quickshell/dock` (arranca con `qs -c dock`):

- **Efecto lupa:** el ícono bajo el cursor crece y los vecinos crecen un poco menos, como en macOS.
- **Apps abiertas:** un punto debajo; una raya más larga si está al frente.
- **Clic:** abre la app o la trae al frente; si ya está al frente, pasa a su siguiente ventana. **Clic central:** abre otra ventana.
- **Se esconde** si una ventana lo tapa; aparece al llevar el cursor al borde de abajo.
- Las apps fijadas se cambian en la lista `fijadas` de `shell.qml`.

KWin no le da a Quickshell la lista de ventanas, así que `ventanas.js` (un script de KWin) la envía por DBus a `puente.py`, que se la pasa al dock.

## Atajos

| Atajo | Qué hace |
|---|---|
| Super + flechas | Mover la ventana dentro del mosaico |
| Super + Shift + flechas / Super + H J K L | Cambiar de ventana |
| Super + Shift + Enter | Hacer esta ventana la principal |
| Super + Ctrl + H / L / K / J | Cambiar el tamaño |
| Super + F | Soltar la ventana del mosaico o volver a meterla |
| Super + D | Lanzador (fuzzel) |
| Super + Shift + M | Dashboard |
| Super + A | HUD |

## Programas necesarios

```
paru -S kwin-scripts-krohnkite kwin-effect-rounded-corners-git plasma6-applets-panel-colorizer \
        alacritty btop cava fastfetch fuzzel quickshell cmatrix tty-clock pipes.sh
```

### Iconos

**BeautyLine Verde**: los iconos de líneas de [BeautyLine](https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline) pasados a la paleta verde. No se suben al repo porque pesan 69 MB; el script los genera:

```
~/.local/bin/iconos-verdes.py
/usr/lib/plasma-changeicons BeautyLine-Verde
```

![Iconos BeautyLine Verde](docs/iconos.png)

Para los iconos que BeautyLine no tiene se usa Colloid-Green-Everforest-Dark como respaldo.

## Uso

- **Instalar en un equipo:** `./instalar.sh` (primero respalda lo que haya).
- **Guardar cambios nuevos en GitHub:** `./guardar.sh`
