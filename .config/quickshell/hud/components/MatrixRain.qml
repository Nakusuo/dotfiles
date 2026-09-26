import QtQuick
import qs

// Lluvia de caracteres como el cmatrix del dashboard. Solo se anima mientras "running" es true.
Item {
    id: root
    property bool running: false
    readonly property int paso: 22                      // ancho de cada columna (px)
    readonly property string letras: "0123456789abcdefghijklmnopqrstuvwxyz$+-*/=%\"'#&_(),.;:?!|{}<>[]^~"

    function cadena(n) {
        let s = "";
        for (let i = 0; i < n; i++) s += letras[Math.floor(Math.random() * letras.length)] + (i < n - 1 ? "\n" : "");
        return s;
    }

    Repeater {
        model: Math.ceil(root.width / root.paso)

        Item {
            id: col
            required property int index
            x: index * root.paso
            width: root.paso
            height: root.height

            property int largo: 8 + Math.floor(Math.random() * 18)
            property int duracion: 3500 + Math.floor(Math.random() * 6000)

            Column {
                id: gota
                y: -height
                Text {
                    id: cola
                    text: root.cadena(col.largo)
                    color: Theme.alpha(Theme.accent, 0.16)
                    font.family: Theme.fontMono; font.pixelSize: 13
                    lineHeight: 1.05
                }
                Text {   // la cabeza de la gota, más clara
                    text: root.cadena(1)
                    color: Theme.alpha(Theme.accentBright, 0.55)
                    font.family: Theme.fontMono; font.pixelSize: 13; font.bold: true
                }
            }

            NumberAnimation {
                target: gota; property: "y"
                from: -gota.height - Math.random() * root.height; to: root.height
                duration: col.duracion
                loops: Animation.Infinite
                running: root.running
            }
        }
    }
}
