import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services

// Reproductor: portada con anillo giratorio, progreso y visualizador cava
HudFrame {
    id: root
    title: "AUDIO LINK"
    width: 400; height: 190

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: {
        const ps = root.players;
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i];
        return ps.length ? ps[0] : null;
    }
    readonly property bool playing: player ? player.isPlaying : false
    tag: player ? player.identity.toUpperCase() : "SIN SEÑAL"

    Binding { target: Cava; property: "active"; value: root.playing && root.visible }

    Timer { interval: 500; running: root.playing; repeat: true; onTriggered: if (root.player) root.player.positionChanged() }

    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60); }

    // visualizador de fondo
    Row {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        height: 60
        Repeater {
            model: Cava.bars
            Rectangle {
                required property int index
                width: (root.width - 40) / Cava.bars - 3
                anchors.bottom: parent.bottom
                height: 2 + (Cava.values.length > index ? Cava.values[index] : 0) * 58
                Behavior on height { NumberAnimation { duration: 70 } }
                color: Theme.alpha(Theme.accent, 0.12 + (Cava.values.length > index ? Cava.values[index] : 0) * 0.35)
            }
        }
    }

    Item {
        id: art
        x: 16; y: 10; width: 104; height: 104
        Arc { anchors.fill: parent; strokeWidth: 1.5; color: Theme.accent; dash: [6, 4]
              RotationAnimation on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite; running: root.playing } }
        Arc { anchors.fill: parent; anchors.margins: 5; strokeWidth: 2; color: Theme.accentBright
              sweep: root.player && root.player.length > 0 ? 360 * root.player.position / root.player.length : 0 }
        Image {
            id: cover
            anchors.fill: parent; anchors.margins: 12
            source: root.player ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false
        }
        Rectangle { id: coverMask; anchors.fill: cover; radius: width / 2; visible: false; layer.enabled: true }
        MultiEffect {
            anchors.fill: cover; source: cover; visible: cover.status === Image.Ready
            maskEnabled: true; maskSource: coverMask
        }
        Text { anchors.centerIn: parent; visible: cover.status !== Image.Ready; text: "󰎈"
               color: Theme.accent; font.family: Theme.fontIcons; font.pixelSize: 34 }
    }

    Column {
        x: art.x + art.width + 16; y: 12
        width: root.width - x - 16
        spacing: 2
        Text { width: parent.width; elide: Text.ElideRight
               text: root.player ? (root.player.trackTitle || "Sin titulo") : "Nada reproduciendose"
               color: Theme.text; font.family: Theme.fontUi; font.pixelSize: 20; font.weight: Font.DemiBold }
        Text { width: parent.width; elide: Text.ElideRight
               text: root.player ? (root.player.trackArtist || "—") : "Abre Spotify o un video"
               color: Theme.accent; font.family: Theme.fontUi; font.pixelSize: 15; font.weight: Font.Medium }
        Item { width: 1; height: 8 }
        // barra de progreso
        Item {
            width: parent.width; height: 12
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 2; color: Theme.alpha(Theme.accent, 0.2) }
            Rectangle {
                id: prog
                anchors.verticalCenter: parent.verticalCenter; height: 2; color: Theme.accent
                width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                Behavior on width { NumberAnimation { duration: 500 } }
            }
            Rectangle { x: prog.width - 4; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; rotation: 45
                        color: Theme.accentBright; visible: prog.width > 0 }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: m => { if (root.player && root.player.canSeek && root.player.length > 0) root.player.position = root.player.length * m.x / width; }
            }
        }
        Row {
            width: parent.width
            Text { text: root.player ? root.fmt(root.player.position) : "0:00"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
            Item { width: parent.width - 60; height: 1 }
            Text { text: root.player ? root.fmt(root.player.length) : "0:00"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11 }
        }
        Row {
            spacing: 22
            anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
                model: [
                    { icon: "󰒮", act: "prev" },
                    { icon: root.playing ? "󰏤" : "󰐊", act: "toggle" },
                    { icon: "󰒭", act: "next" }
                ]
                Text {
                    required property var modelData
                    text: modelData.icon
                    color: ma.containsMouse ? Theme.accentBright : Theme.text
                    font.family: Theme.fontIcons; font.pixelSize: modelData.act === "toggle" ? 30 : 22
                    anchors.verticalCenter: parent.verticalCenter
                    scale: ma.pressed ? 0.85 : ma.containsMouse ? 1.15 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        id: ma; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.player) return;
                            if (modelData.act === "prev") root.player.previous();
                            else if (modelData.act === "next") root.player.next();
                            else root.player.togglePlaying();
                        }
                    }
                }
            }
        }
    }
}
