# Dotfiles — KDE Plasma "Verde Tech"

Mi rice de KDE Plasma 6 (CachyOS, Wayland) con aspecto tipo Hyprland: paleta verde apagada, ventanas en mosaico y un dashboard de terminales.

![Fondo](Imágenes/wallpaper-tech.png)

## Qué incluye

- **Colores:** esquema `VerdeTech` (y la demo `RojoTech`) para KDE, Konsole, Alacritty, btop, cava, fastfetch y fuzzel.
- **Mosaico:** Krohnkite con huecos de 10 px, esquinas redondeadas y 5 escritorios.
- **Dashboard:** `dashboard.sh` abre btop, reloj, cmatrix y pipes en mosaico al iniciar sesión (Super+Shift+M).
- **Cambio de tema:** `tema.sh verde` o `tema.sh rojo`.
- **HUD:** Quickshell en `.config/quickshell/hud` (Super+A).

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
