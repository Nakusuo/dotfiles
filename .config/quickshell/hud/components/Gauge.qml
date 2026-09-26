import QtQuick
import qs

// Medidor circular con valor animado
Item {
    id: root
    property real value: 0
    property string label: ""
    property string detail: ""
    property color color: value > 0.85 ? Theme.danger : value > 0.65 ? Theme.warn : Theme.accent
    width: 96; height: 96

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    Arc { anchors.fill: parent; strokeWidth: 1; color: Theme.alpha(Theme.accent, 0.25); dash: [2, 3] }
    Arc { anchors.fill: parent; anchors.margins: 8; strokeWidth: 5; color: Theme.alpha(root.color, 0.12); startAngle: 135; sweep: 270 }
    Arc { anchors.fill: parent; anchors.margins: 8; strokeWidth: 5; color: root.color; startAngle: 135; sweep: 270 * root.shown
        Behavior on color { ColorAnimation { duration: 400 } } }
    Arc {
        anchors.fill: parent; anchors.margins: 18; strokeWidth: 1; color: Theme.alpha(Theme.accent2, 0.6)
        sweep: 60; dash: [4, 2]
        RotationAnimation on rotation { from: 0; to: 360; duration: 9000 - root.value * 6000; loops: Animation.Infinite }
    }
    Column {
        anchors.centerIn: parent
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.shown * 100) + "%"
               color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: 17; font.weight: Font.Bold }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.label
               color: root.color; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 2 }
    }
    Text {
        visible: root.detail !== ""
        anchors.top: parent.bottom; anchors.topMargin: 2; anchors.horizontalCenter: parent.horizontalCenter
        text: root.detail; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10
    }
}
