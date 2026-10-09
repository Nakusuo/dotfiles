import QtQuick
import qs

// Marco HUD como una ventana de Windows 98 en verde fósforo:
// barra de título con degradado, botones _ □ × y bordes biselados
Item {
    id: root
    property string title: ""
    property string tag: ""
    property color lineColor: Theme.accent
    // colores de la barra de título (la alerta los cambia a rojo)
    property color tituloA: Theme.tituloA
    property color tituloB: Theme.tituloB
    default property alias content: inner.data
    readonly property int altoTitulo: 22

    // cuerpo
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.9)
    }
    // bisel: claro arriba/izquierda, oscuro abajo/derecha
    Rectangle { width: parent.width; height: Theme.border; color: Theme.alpha(Theme.biselClaro, 0.85) }
    Rectangle { width: Theme.border; height: parent.height; color: Theme.alpha(Theme.biselClaro, 0.85) }
    Rectangle { y: parent.height - Theme.border; width: parent.width; height: Theme.border; color: Theme.biselOscuro }
    Rectangle { x: parent.width - Theme.border; width: Theme.border; height: parent.height; color: Theme.biselOscuro }

    // barra de título
    Rectangle {
        id: barra
        visible: root.title !== ""
        x: Theme.border + 2; y: Theme.border + 2
        width: parent.width - 2 * (Theme.border + 2); height: root.altoTitulo
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.tituloA }
            GradientStop { position: 1; color: root.tituloB }
        }
        Text {
            x: 6; anchors.verticalCenter: parent.verticalCenter
            text: root.title; color: "#ffffff"
            font.family: Theme.fontDisplay; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
        }
        Row {
            anchors { right: parent.right; rightMargin: 3; verticalCenter: parent.verticalCenter }
            spacing: 2
            Text {
                visible: root.tag !== ""
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: 6
                text: root.tag; color: Theme.alpha("#ffffff", 0.8)
                font.family: Theme.fontMono; font.pixelSize: 10
            }
            Repeater {
                model: ["_", "□", "×"]
                Rectangle {   // botón con relieve
                    required property string modelData
                    width: 16; height: 14
                    color: Theme.dim
                    border.width: 1; border.color: Theme.biselClaro
                    Rectangle { anchors { right: parent.right; bottom: parent.bottom } width: parent.width; height: 1; color: Theme.biselOscuro }
                    Rectangle { anchors { right: parent.right; bottom: parent.bottom } width: 1; height: parent.height; color: Theme.biselOscuro }
                    Text { anchors.centerIn: parent; text: parent.modelData; color: Theme.text
                           font.family: Theme.fontMono; font.pixelSize: 10; font.bold: true }
                }
            }
        }
    }

    Item { id: inner; anchors.fill: parent; anchors.topMargin: root.title !== "" ? root.altoTitulo + 10 : 0 }
}
