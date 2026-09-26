import QtQuick
import Quickshell
import qs

// Disposicion del HUD de escritorio, con entrada escalonada
Item {
    id: root
    property bool revealed: true
    property alias reactor: reactor
    property alias music: music
    property alias stats: stats
    readonly property int top: 60

    property date now: new Date()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.now = new Date() }
    readonly property string greeting: {
        const h = now.getHours();
        return h < 6 ? "BUENA MADRUGADA" : h < 12 ? "BUENOS DIAS" : h < 19 ? "BUENAS TARDES" : "BUENAS NOCHES";
    }

    component Reveal: Item {
        id: rv
        property int delay: 0
        property bool on: root.revealed
        property real dy: 30
        opacity: 0
        transform: Translate { y: rv.dy }
        onOnChanged: anim.restart()
        Component.onCompleted: anim.restart()
        SequentialAnimation {
            id: anim
            PauseAnimation { duration: rv.on ? rv.delay : 0 }
            ParallelAnimation {
                NumberAnimation { target: rv; property: "opacity"; to: rv.on ? 1 : 0; duration: 420; easing.type: Easing.OutCubic }
                NumberAnimation { target: rv; property: "dy"; to: rv.on ? 0 : 30; duration: 520; easing.type: Easing.OutCubic }
            }
        }
    }

    Reveal {
        delay: 0
        x: 60; y: root.top + 20
        width: reactor.width; height: reactor.height
        Reactor { id: reactor }
    }

    Reveal {
        delay: 120
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.top + 40
        width: greet.width; height: greet.height
        Column {
            id: greet
            spacing: 6
            Text {
                id: hello
                property string full: root.greeting + ", " + (Quickshell.env("USER") || "").toUpperCase()
                property int shown: 0
                text: full.substring(0, shown) + (shown < full.length ? "█" : "")
                color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 22; font.letterSpacing: 4
                Timer { interval: 45; running: hello.shown < hello.full.length && root.revealed; repeat: true; onTriggered: hello.shown++ }
                Connections { target: root; function onRevealedChanged() { if (root.revealed) hello.shown = 0; } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TODOS LOS SISTEMAS EN LINEA"
                color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 12; font.letterSpacing: 5
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 1400 } NumberAnimation { to: 1; duration: 1400 } }
            }
        }
    }

    Reveal {
        delay: 200
        x: parent.width - stats.width - 50; y: root.top + 20
        width: stats.width; height: stats.height
        StatsPanel { id: stats }
    }

    Reveal {
        delay: 300
        x: 50; y: parent.height - music.height - 110
        width: music.width; height: music.height
        MusicPanel { id: music }
    }
}
