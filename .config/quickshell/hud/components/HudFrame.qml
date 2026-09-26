import QtQuick
import qs

// Marco HUD con el estilo de las ventanas del dashboard
Item {
    id: root
    property string title: ""
    property string tag: ""
    property color lineColor: Theme.accent
    default property alias content: inner.data

    // Igual que una terminal del dashboard: fondo translúcido, esquinas redondeadas y borde verde
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.alpha(Theme.bg, 0.85)
        border.color: root.lineColor
        border.width: Theme.border
    }

    // cabecera
    Row {
        visible: root.title !== ""
        x: 14; y: 8; spacing: 8
        Rectangle { width: 6; height: 6; radius: 1; color: root.lineColor; anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity { loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 900 } NumberAnimation { to: 1; duration: 900 } }
        }
        Text { text: root.title; color: root.lineColor; font.family: Theme.fontDisplay; font.pixelSize: 10; font.letterSpacing: 3 }
    }
    Text {
        visible: root.tag !== ""
        anchors.right: parent.right; anchors.rightMargin: 14; y: 8
        text: root.tag; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 1
    }

    Item { id: inner; anchors.fill: parent; anchors.topMargin: root.title !== "" ? 26 : 0 }
}
