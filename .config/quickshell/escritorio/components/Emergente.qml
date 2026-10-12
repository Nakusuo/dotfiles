import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Capa transparente que tapa la pantalla (menos la barra) mientras hay algo abierto:
// un clic fuera o Esc lo cierra. Dentro va el panel, el lanzador o el menú de apagado.
PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "verdetech-emergente"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea { anchors.fill: parent; onClicked: Estado.cerrar() }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Estado.cerrar()

        Loader {
            anchors.fill: parent
            focus: true
            sourceComponent: Estado.abierto === "panel" ? panel
                           : Estado.abierto === "lanzador" ? lanzador
                           : menu
        }
    }

    Component { id: panel; Panel {} }
    Component { id: lanzador; Lanzador {} }
    Component { id: menu; MenuApagado {} }
}
