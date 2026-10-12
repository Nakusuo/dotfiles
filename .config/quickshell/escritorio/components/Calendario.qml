import QtQuick
import qs

// El mes en una cuadrícula verde; hoy relleno de lima. ◀ ▶ cambian de mes.
Column {
    id: root
    spacing: 4
    readonly property var meses: ["ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO", "JULIO",
                                  "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"]
    readonly property date hoy: new Date()
    property int desplazamiento: 0
    readonly property date primero: new Date(hoy.getFullYear(), hoy.getMonth() + desplazamiento, 1)
    readonly property int inicio: (primero.getDay() + 6) % 7   // la semana empieza en lunes
    readonly property int dias: new Date(primero.getFullYear(), primero.getMonth() + 1, 0).getDate()
    readonly property int celda: Math.floor(width / 7)

    Item {
        width: parent.width; height: 22
        Boton { anchors.left: parent.left; texto: "◀"; implicitHeight: 20; onPulsado: root.desplazamiento-- }
        Text {
            anchors.centerIn: parent
            text: root.meses[root.primero.getMonth()] + " " + root.primero.getFullYear()
            color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 12; font.bold: true
        }
        Boton { anchors.right: parent.right; texto: "▶"; implicitHeight: 20; onPulsado: root.desplazamiento++ }
    }

    Grid {
        columns: 7
        Repeater {
            model: ["LU", "MA", "MI", "JU", "VI", "SA", "DO"]
            Text {
                required property string modelData
                width: root.celda; horizontalAlignment: Text.AlignHCenter
                text: modelData; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10
            }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property int dia: index - root.inicio + 1
                readonly property bool esHoy: root.desplazamiento === 0 && dia === root.hoy.getDate()
                width: root.celda; height: 17
                color: esHoy ? "#b6f06a" : "transparent"
                Text {
                    anchors.centerIn: parent
                    visible: parent.dia >= 1 && parent.dia <= root.dias
                    text: parent.dia
                    color: parent.esHoy ? Theme.bg : Theme.text
                    font.family: Theme.fontMono; font.pixelSize: 11; font.bold: parent.esHoy
                }
            }
        }
    }
}
