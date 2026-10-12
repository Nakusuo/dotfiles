import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

// Panel que sale de la barra: música, calendario, clima, sistema y avisos.
// Solo existe mientras está abierto, así que nada de esto gasta en reposo.
Item {
    id: raiz

    Rectangle {
        id: hoja
        width: 420; height: parent.height
        x: Estado.ligero ? 0 : -width
        color: Theme.alpha(Theme.bg, 0.96)
        Component.onCompleted: if (!Estado.ligero) entrada.start()
        NumberAnimation { id: entrada; target: hoja; property: "x"; to: 0; duration: 220; easing.type: Easing.OutCubic }

        MouseArea { anchors.fill: parent }   // los clics dentro no cierran el panel
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.alpha(Theme.accent, 0.35) }

        // un solo barrido de scanline al abrir
        Rectangle {
            id: barrido
            width: parent.width; height: 2
            color: Theme.alpha("#b6f06a", 0.6)
            visible: !Estado.ligero && y < hoja.height
            NumberAnimation on y { from: 0; to: hoja.height; duration: 420; running: !Estado.ligero }
        }

        // cabecera de cámara
        TextoNvg { x: 16; y: 12; text: "Standard NVG · 40° FOV" }
        Row {
            anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 12 }
            spacing: 6
            property int segundos: 0
            Timer { interval: 1000; repeat: true; running: true; onTriggered: parent.segundos++ }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.alerta }
            Text {
                readonly property int s: parent.segundos
                text: "REC " + ("0" + Math.floor(s / 3600)).slice(-2) + ":" + ("0" + Math.floor(s % 3600 / 60)).slice(-2) + ":" + ("0" + s % 60).slice(-2)
                color: Theme.alerta; font.family: Theme.fontMono; font.pixelSize: 13; font.bold: true
            }
        }

        Flickable {
            anchors { fill: parent; topMargin: 40; leftMargin: 12; rightMargin: 12; bottomMargin: 8 }
            contentHeight: columna.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: columna
                width: parent.width
                spacing: 10

                VentanaW98 {
                    width: parent.width; titulo: "MÚSICA.EXE"
                    Musica { width: parent.width }
                }

                VentanaW98 {
                    width: parent.width; titulo: "CALENDARIO"
                    Calendario { width: parent.width }
                }

                VentanaW98 {
                    width: parent.width; titulo: "CLIMA"
                    Clima { width: parent.width }
                }

                VentanaW98 {
                    width: parent.width; titulo: "SISTEMA"
                    Binding { target: SysStats; property: "active"; value: true }
                    Repeater {
                        model: [
                            { n: "CPU", v: SysStats.cpu },
                            { n: "RAM", v: SysStats.ram },
                            { n: "BAT", v: SysStats.battery }
                        ]
                        Row {
                            required property var modelData
                            spacing: 8
                            Text { width: 34; text: modelData.n; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 12 }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 240; height: 10; color: "transparent"
                                border.width: 1; border.color: Theme.alpha(Theme.accent, 0.5)
                                Rectangle {
                                    x: 2; y: 2; height: parent.height - 4
                                    width: (parent.width - 4) * Math.max(0, Math.min(1, modelData.v))
                                    color: modelData.v > 0.85 && modelData.n !== "BAT" ? Theme.alerta : "#b6f06a"
                                }
                            }
                            Text { text: Math.round(modelData.v * 100) + "%"; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 12 }
                        }
                    }
                    Text { text: "ENCENDIDO " + SysStats.uptime; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
                }

                VentanaW98 {
                    width: parent.width; titulo: "AVISOS (" + Estado.avisos.length + ")"
                    Text {
                        visible: Estado.avisos.length === 0
                        text: "Sin avisos"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 12
                    }
                    Repeater {
                        model: Estado.avisos
                        Column {
                            required property var modelData
                            width: parent.width
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: modelData.hora + "  " + modelData.app + " · " + modelData.titulo
                                color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 11
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight; maximumLineCount: 1
                                visible: text.length > 0
                                text: modelData.texto; textFormat: Text.PlainText
                                color: Theme.muted; font.family: Theme.fontUi; font.pixelSize: 11
                            }
                        }
                    }
                    Boton {
                        visible: Estado.avisos.length > 0
                        texto: "Borrar"
                        onPulsado: Estado.avisos = []
                    }
                }
            }
        }
    }
}
