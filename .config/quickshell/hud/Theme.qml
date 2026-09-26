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
    readonly property color bg: "#0a0f0c"
    readonly property color warn: "#d4b56a"
    readonly property color danger: "#d0776f"

    readonly property string fontDisplay: "Orbitron"
    readonly property string fontUi: "Rajdhani"
    readonly property string fontMono: "Share Tech Mono"
    readonly property string fontIcons: "FiraMono Nerd Font"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
}
