import QtQuick
import QtQuick.Effects
import qs

// Reloj "reactor": anillos que giran, barrido de segundos continuo
Item {
    id: root
    width: 300; height: 300

    property date now: new Date()
    property real secFrac: 0
    Timer {
        interval: 33; running: root.visible; repeat: true; triggeredOnStart: true
        onTriggered: { root.now = new Date(); root.secFrac = (root.now.getSeconds() + root.now.getMilliseconds() / 1000) / 60; }
    }
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    readonly property var days: ["DOM", "LUN", "MAR", "MIE", "JUE", "VIE", "SAB"]
    readonly property var months: ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"]

    Item {
        id: rings
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: Theme.accent; shadowBlur: 0.8; blurMax: 24
            shadowHorizontalOffset: 0; shadowVerticalOffset: 0; shadowOpacity: 0.7
        }

        // marcas de minuto
        Repeater {
            model: 60
            Rectangle {
                required property int index
                x: root.width / 2 - width / 2; y: 4
                width: index % 5 === 0 ? 3 : 1; height: index % 5 === 0 ? 12 : 6
                color: index <= Math.floor(root.secFrac * 60) ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                transform: Rotation { origin.x: width / 2; origin.y: root.height / 2 - 4; angle: index * 6 }
            }
        }
        // anillo exterior punteado girando
        Arc { anchors.fill: parent; anchors.margins: 22; strokeWidth: 1.5; color: Theme.alpha(Theme.accent2, 0.7); dash: [8, 5]
              RotationAnimation on rotation { from: 0; to: 360; duration: 40000; loops: Animation.Infinite } }
        // segmentos que giran en sentido contrario
        Repeater {
            model: 3
            Arc {
                required property int index
                anchors.fill: parent; anchors.margins: 34; strokeWidth: 4
                color: Theme.alpha(Theme.accent, 0.55); startAngle: index * 120; sweep: 70
                RotationAnimation on rotation { from: 360; to: 0; duration: 14000; loops: Animation.Infinite }
            }
        }
        // barrido de segundos
        Arc { anchors.fill: parent; anchors.margins: 48; strokeWidth: 3; color: Theme.alpha(Theme.accent, 0.12) }
        Arc { anchors.fill: parent; anchors.margins: 48; strokeWidth: 3; color: Theme.accentBright; sweep: 360 * root.secFrac }
        // nucleo
        Arc { anchors.fill: parent; anchors.margins: 62; strokeWidth: 1; color: Theme.alpha(Theme.accent, 0.4); dash: [1, 3] }
        Rectangle {
            anchors.centerIn: parent; width: parent.width - 150; height: width; radius: width / 2
            color: "transparent"; border.color: Theme.alpha(Theme.accent, 0.35); border.width: 1
            SequentialAnimation on border.width { loops: Animation.Infinite
                NumberAnimation { to: 3; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1600; easing.type: Easing.InOutSine } }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())
            color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 42; font.weight: Font.Bold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.pad(root.now.getSeconds()) + "  //  " + root.days[root.now.getDay()]
            color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 13; font.letterSpacing: 3
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.pad(root.now.getDate()) + " " + root.months[root.now.getMonth()] + " " + root.now.getFullYear()
            color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11; font.letterSpacing: 2
        }
    }
}
