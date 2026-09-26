import QtQuick
import QtQuick.Effects
import qs
import qs.services

// Centro de la barra: hora | hexagonos de escritorios | fecha
Item {
    id: root
    implicitWidth: row.implicitWidth + 24
    implicitHeight: 34

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    readonly property var days: ["DOM", "LUN", "MAR", "MIE", "JUE", "VIE", "SAB"]
    readonly property var months: ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"]

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())
            color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 1
        }

        Item {
            id: hexes
            width: hexRow.width; height: 34
            anchors.verticalCenter: parent.verticalCenter

            // brillo que se desliza bajo el escritorio activo
            Rectangle {
                id: glide
                width: 22; height: 2; radius: 1; y: 31; color: Theme.accentBright
                x: (Desktops.current - 1) * (28 + 6) + 3
                Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.accent; shadowBlur: 1; blurMax: 12; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
            }

            Row {
                id: hexRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Repeater {
                    model: Desktops.count
                    Item {
                        id: cell
                        required property int index
                        readonly property bool active: Desktops.current === index + 1
                        width: 28; height: 28
                        scale: active ? 1.12 : ma.containsMouse ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

                        Hexagon {
                            anchors.fill: parent
                            fill: cell.active ? Theme.accent : ma.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"
                            stroke: cell.active ? Theme.accentBright : Theme.alpha(Theme.accent, 0.55)
                            Behavior on fill { ColorAnimation { duration: 250 } }
                        }
                        Hexagon {
                            visible: cell.active
                            anchors.fill: parent; anchors.margins: -4; strokeWidth: 1
                            stroke: Theme.alpha(Theme.accent, 0.5)
                            RotationAnimation on rotation { from: 0; to: 360; duration: 6000; loops: Animation.Infinite; running: cell.active }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: cell.index + 1
                            color: cell.active ? Theme.bg : Theme.text
                            font.family: Theme.fontDisplay; font.pixelSize: 11; font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Desktops.go(cell.index + 1)
                        }
                    }
                }
            }
            WheelHandler {
                onWheel: e => { if (e.angleDelta.y < 0) Desktops.next(); else Desktops.prev(); }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.days[root.now.getDay()] + " " + root.pad(root.now.getDate()) + " " + root.months[root.now.getMonth()]
            color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 13; font.letterSpacing: 2
        }
    }
}
