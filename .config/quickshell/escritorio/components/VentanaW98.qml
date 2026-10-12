import QtQuick
import qs

// Ventana tipo Windows 98 en verde fósforo: bisel de 2 px y barra de título en degradado.
// roja: la de alerta (警告). El contenido va en una columna.
Rectangle {
    id: root
    property string titulo: ""
    property bool roja: false
    property bool cerrable: false
    property int relleno: 10
    default property alias contenido: cuerpo.data
    signal cerrada()

    implicitWidth: 300
    implicitHeight: cuerpo.y + cuerpo.implicitHeight + relleno + 2
    color: Theme.bg

    // se traga los clics para que no lleguen a lo que hay detrás (que cerraría el panel)
    MouseArea { anchors.fill: parent }

    // bisel: claro arriba/izquierda, oscuro abajo/derecha
    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: Theme.border; color: Theme.biselClaro }
    Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: Theme.border; color: Theme.biselClaro }
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Theme.border; color: Theme.biselOscuro }
    Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: Theme.border; color: Theme.biselOscuro }

    Rectangle {
        id: barra
        x: 3; y: 3; width: parent.width - 6; height: 20
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.roja ? Theme.alerta : Theme.tituloA }
            GradientStop { position: 1; color: root.roja ? "#6b1a1f" : Theme.tituloB }
        }
        Text {
            anchors { left: parent.left; leftMargin: 6; right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
            text: root.titulo; elide: Text.ElideRight
            color: "#e4ffc4"; font.family: Theme.fontMono; font.pixelSize: 12; font.bold: true
        }
        Rectangle {
            visible: root.cerrable
            anchors { right: parent.right; rightMargin: 3; verticalCenter: parent.verticalCenter }
            width: 16; height: 14; color: Theme.bg
            border.color: Theme.biselClaro; border.width: 1
            Text { anchors.centerIn: parent; text: "×"; color: Theme.text; font.pixelSize: 12; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.cerrada() }
        }
    }

    Column {
        id: cuerpo
        x: root.relleno + 2
        y: barra.y + barra.height + root.relleno
        width: root.width - 2 * root.relleno - 4
        spacing: 6
    }
}
