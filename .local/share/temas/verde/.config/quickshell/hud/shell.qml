import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components

// HUD futurista sobre KDE Plasma
//  - Capa de escritorio: reactor, sistema y musica (debajo de las ventanas)
//  - Barra: hexagonos de escritorios en el centro del panel de Plasma
//  - Super+A: invoca el HUD por encima de todo (Esc o clic para cerrar)
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

            // HUD de escritorio: solo los widgets reciben clics
            PanelWindow {
                screen: scope.modelData
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "hud-desktop"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }
                color: "transparent"

                HudLayout {
                    id: deskHud
                    anchors.fill: parent
                    revealed: !shell.summoned
                }
                mask: Region {
                    Region { item: deskHud.reactor }
                    Region { item: deskHud.stats }
                    Region { item: deskHud.music }
                }
            }

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
                    color: "#d9050a07"
                    opacity: shell.summoned ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                    // lineas de escaneo
                    Column {
                        anchors.fill: parent
                        Repeater {
                            model: Math.ceil(overlay.height / 4)
                            Rectangle { width: overlay.width; height: 4; color: index % 2 ? "transparent" : "#0a6cc196" }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: shell.summoned = false }
                }

                HudLayout {
                    anchors.fill: parent
                    revealed: shell.summoned
                }

                Item {
                    anchors.fill: parent
                    focus: shell.summoned
                    Keys.onEscapePressed: shell.summoned = false
                }
            }

            // Centro de la barra superior
            PanelWindow {
                screen: scope.modelData
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "hud-bar"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true }
                implicitWidth: bar.implicitWidth
                implicitHeight: 34
                color: "transparent"
                WorkspaceBar { id: bar; anchors.fill: parent }
            }
        }
    }
}
