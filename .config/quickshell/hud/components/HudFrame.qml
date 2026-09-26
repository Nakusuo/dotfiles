import QtQuick
import qs

// Marco HUD: fondo translucido, borde fino, esquinas en escuadra y barrido de escaneo
Item {
    id: root
    property string title: ""
    property string tag: ""
    property int corner: 14
    property color lineColor: Theme.accent
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.62)
        border.color: Theme.alpha(root.lineColor, 0.18)
        border.width: 1
        clip: true

        // barrido de escaneo
        Rectangle {
            id: scan
            width: parent.width; height: 40
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Theme.alpha(root.lineColor, 0.07) }
            }
            NumberAnimation on y {
                from: -40; to: root.height; duration: 4200
                loops: Animation.Infinite; easing.type: Easing.InOutSine
            }
        }
    }

    // escuadras
    Repeater {
        model: 4
        Item {
            required property int index
            width: root.corner; height: root.corner
            x: index % 2 === 0 ? -1 : root.width - width + 1
            y: index < 2 ? -1 : root.height - height + 1
            Rectangle { width: parent.width; height: 2; color: root.lineColor; y: index < 2 ? 0 : parent.height - 2 }
            Rectangle { width: 2; height: parent.height; color: root.lineColor; x: index % 2 === 0 ? 0 : parent.width - 2 }
        }
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
