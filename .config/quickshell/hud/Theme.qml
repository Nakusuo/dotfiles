pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Paleta "Verde Tech" en clave HUD
    readonly property color accent: "#6cc196"
    readonly property color accent2: "#5fa8a0"
    readonly property color accentBright: "#8fd3ae"
    readonly property color dim: "#3a4a41"
    readonly property color text: "#cfdcd4"
    readonly property color muted: "#7d9186"
    readonly property color bg: "#0d1310"          // fondo de Alacritty
    readonly property color warn: "#d4b56a"
    readonly property color danger: "#d0776f"

    // Estética cyberpunk 2000: ventanas tipo Windows 98 en verde fósforo
    readonly property color alerta: "#d0443a"       // el rojo del 警告
    readonly property color tituloA: "#2f6b4e"      // degradado de la barra de título
    readonly property color tituloB: "#5fa8a0"
    readonly property color biselClaro: "#8fd3ae"   // borde de arriba/izquierda
    readonly property color biselOscuro: "#050806"  // borde de abajo/derecha

    readonly property string fontDisplay: "JetBrainsMono Nerd Font"   // la misma letra de las terminales del dashboard
    readonly property string fontUi: "JetBrainsMono Nerd Font"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontIcons: "FiraMono Nerd Font"

    // Ventanas Y2K: esquinas rectas y bisel de 2 px
    readonly property int radius: 0
    readonly property int border: 2

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
