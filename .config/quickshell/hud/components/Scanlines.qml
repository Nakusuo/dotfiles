import QtQuick

// Líneas de televisor CRT por encima de todo (estáticas: no gastan nada)
Column {
    id: root
    property int paso: 3
    enabled: false   // no tapa los clics
    Repeater {
        model: Math.ceil(root.height / root.paso)
        Item {
            width: root.width; height: root.paso
            Rectangle { width: parent.width; height: 1; color: "#40000000" }
        }
    }
}
