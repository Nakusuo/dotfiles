import QtQuick
import qs

// Botón Windows 98 (bisel que se hunde al pulsar)
Rectangle {
    id: root
    property string texto: ""
    property bool rojo: false
    signal pulsado()

    implicitWidth: etiqueta.implicitWidth + 20
    implicitHeight: 24
    color: zona.containsMouse ? Theme.alpha(rojo ? Theme.alerta : Theme.accent, 0.18) : Theme.bg
    border.width: 0

    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: zona.pressed ? Theme.biselOscuro : Theme.biselClaro }
    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 1; color: zona.pressed ? Theme.biselOscuro : Theme.biselClaro }
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: zona.pressed ? Theme.biselClaro : Theme.biselOscuro }
    Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: zona.pressed ? Theme.biselClaro : Theme.biselOscuro }

    Text {
        id: etiqueta
        anchors.centerIn: parent
        text: root.texto
        color: root.rojo ? Theme.danger : Theme.text
        font.family: Theme.fontMono; font.pixelSize: 12
    }
    MouseArea { id: zona; anchors.fill: parent; hoverEnabled: true; onClicked: root.pulsado() }
}
