import QtQuick
import qs

// Pantalla de videocámara de visión nocturna (cyberpunk 2000 / Fallen Angels):
// «Standard NVG» arriba a la izquierda, ALT arriba a la derecha,
// ZOOM abajo a la izquierda y el contador REC en rojo abajo al centro
Item {
    id: root
    readonly property color verdeNvg: "#b6f06a"
    property int segundos: 0   // tiempo grabando: cuenta desde que se abre el HUD

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.segundos++ }
    function dos(n) { return (n < 10 ? "0" : "") + n; }

    component Etiqueta: Text {
        color: root.verdeNvg
        font.family: Theme.fontMono; font.pixelSize: 16
        style: Text.Outline; styleColor: "#80000000"
    }

    Column {
        x: 28; y: 18
        Etiqueta { text: "Standard NVG" }
        Etiqueta { text: "40° FOV"; font.pixelSize: 28 }
    }

    Row {
        anchors { right: parent.right; rightMargin: 28; top: parent.top; topMargin: 22 }
        spacing: 10
        Rectangle {
            width: alt.implicitWidth + 12; height: 30; color: Theme.alerta
            Text { id: alt; anchors.centerIn: parent; text: "ALT"; color: "#101010"
                   font.family: Theme.fontMono; font.pixelSize: 22; font.bold: true }
        }
        Rectangle {
            width: 30; height: 30; radius: 15
            color: "transparent"; border.width: 2; border.color: root.verdeNvg
            Etiqueta { anchors.centerIn: parent; text: "i"; font.pixelSize: 18; font.bold: true }
        }
    }

    Rectangle {
        anchors { left: parent.left; leftMargin: 28; bottom: parent.bottom; bottomMargin: 26 }
        width: zoom.implicitWidth + 10; height: zoom.implicitHeight + 4
        color: "transparent"; border.width: 2; border.color: root.verdeNvg
        Etiqueta { id: zoom; anchors.centerIn: parent; text: "ZOOM"; font.pixelSize: 13 }
    }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 20 }
        spacing: 12
        Text {   // punto de grabación que parpadea
            anchors.verticalCenter: parent.verticalCenter
            text: "● REC"; color: Theme.alerta
            font.family: Theme.fontMono; font.pixelSize: 16; font.bold: true
            opacity: root.segundos % 2 ? 0.25 : 1
        }
        Text {
            text: root.dos(Math.floor(root.segundos / 3600)) + ":" + root.dos(Math.floor(root.segundos / 60) % 60) + ":" + root.dos(root.segundos % 60)
            color: Theme.alerta
            font.family: Theme.fontMono; font.pixelSize: 30; font.bold: true
            style: Text.Outline; styleColor: "#80000000"
        }
    }

    Etiqueta {
        anchors { right: parent.right; rightMargin: 28; bottom: parent.bottom; bottomMargin: 24 }
        text: "((•))"; font.pixelSize: 18
    }
}
