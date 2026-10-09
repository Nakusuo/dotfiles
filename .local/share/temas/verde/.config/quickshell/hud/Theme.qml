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

    readonly property string fontDisplay: "JetBrainsMono Nerd Font"   // la misma letra de las terminales del dashboard
    readonly property string fontUi: "JetBrainsMono Nerd Font"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontIcons: "FiraMono Nerd Font"

    // Marcos como las ventanas del dashboard: esquinas de 12 px y borde verde de 2 px
    readonly property int radius: 12
    readonly property int border: 2

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
