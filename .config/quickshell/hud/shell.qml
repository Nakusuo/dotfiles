import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components

// HUD futurista sobre KDE Plasma, con el estilo del dashboard (Super+Shift+M)
//  - Super+A: muestra reloj, sistema y música por encima de todo, sobre una lluvia tipo cmatrix
//  - Esc o clic para cerrar
ShellRoot {
    id: shell
    property bool summoned: false

    IpcHandler {
        target: "hud"
        function toggle(): void { shell.summoned = !shell.summoned; }
        function show(): void { shell.summoned = true; }
        function hide(): void { shell.summoned = false; }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property var modelData

            // HUD invocado por encima de todo
            PanelWindow {
                id: overlay
                screen: scope.modelData
                visible: shell.summoned || backdrop.opacity > 0.01
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "hud-overlay"
                WlrLayershell.keyboardFocus: shell.summoned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                Rectangle {
                    id: backdrop
                    anchors.fill: parent
                    color: "#f20a0f0c"
                    opacity: shell.summoned ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                    // lluvia verde, como el cmatrix del dashboard
                    // (Loader: cerrado, el HUD no existe y no gasta CPU; antes sus animaciones seguían corriendo escondidas)
                    Loader {
                        anchors.fill: parent
                        active: overlay.visible
                        sourceComponent: MatrixRain { running: shell.summoned }
                    }
                    MouseArea { anchors.fill: parent; onClicked: shell.summoned = false }
                }

                Loader {
                    anchors.fill: parent
                    active: overlay.visible
                    sourceComponent: HudLayout { revealed: shell.summoned }
                }

                // líneas de televisor CRT por encima de todo
                Loader {
                    anchors.fill: parent
                    active: overlay.visible
                    opacity: backdrop.opacity
                    sourceComponent: Scanlines {}
                }

                Item {
                    anchors.fill: parent
                    focus: shell.summoned
                    Keys.onEscapePressed: shell.summoned = false
                }
            }
        }
    }
}
