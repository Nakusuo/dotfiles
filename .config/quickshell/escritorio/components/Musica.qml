import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.services

// Música ligera para el panel: título, artista, progreso, controles y barras de cava.
// cava solo corre mientras suena y el panel está abierto (al cerrarlo, el Binding se deshace).
Column {
    id: root
    spacing: 6
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool sonando: player ? player.isPlaying : false

    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60); }

    Binding { target: Cava; property: "active"; value: root.sonando }
    // MPRIS no avisa del avance: se pide una vez por segundo, solo mientras suena
    Timer { interval: 1000; repeat: true; running: root.sonando; onTriggered: root.player.positionChanged() }

    Text {
        width: parent.width; elide: Text.ElideRight
        text: root.player ? (root.player.trackTitle || "Sin título") : "NO TAPE"
        color: Theme.text; font.family: Theme.fontUi; font.pixelSize: 14; font.bold: true
    }
    Text {
        width: parent.width; elide: Text.ElideRight
        visible: !!root.player
        text: root.player ? (root.player.trackArtist || "") : ""
        color: Theme.accent; font.family: Theme.fontUi; font.pixelSize: 12
    }

    // barras de cava
    Row {
        visible: root.sonando
        height: 24; spacing: 2
        Repeater {
            model: Cava.values.length
            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: (root.width - 2 * (Cava.values.length - 1)) / Math.max(1, Cava.values.length)
                height: 2 + Cava.values[index] * 22
                color: Theme.alpha(Theme.accent, 0.3 + Cava.values[index] * 0.6)
            }
        }
    }

    // progreso
    Item {
        visible: !!root.player && root.player.length > 0
        width: parent.width; height: 14
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: Theme.alpha(Theme.accent, 0.2) }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter; height: 2; color: "#b6f06a"
            width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        visible: !!root.player
        Boton { texto: "󰒮"; onPulsado: root.player.previous() }
        Boton { texto: root.sonando ? "󰏤" : "󰐊"; onPulsado: root.player.togglePlaying() }
        Boton { texto: "󰒭"; onPulsado: root.player.next() }
        TextoNvg {
            anchors.verticalCenter: parent.verticalCenter
            text: root.player ? root.fmt(root.player.position) + " / " + root.fmt(root.player.length) : ""
            font.pixelSize: 11
        }
    }
}
