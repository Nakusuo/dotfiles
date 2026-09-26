import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

HudFrame {
    id: root
    title: "SYSTEM CORE"
    tag: "UP " + SysStats.uptime
    width: 250; height: 330

    property string host: ""
    Process {
        running: true
        command: ["uname", "-nr"]
        stdout: SplitParser { onRead: d => root.host = d.trim().toUpperCase() }
    }

    Grid {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        columns: 2; columnSpacing: 22; rowSpacing: 26
        Gauge { value: SysStats.cpu; label: "CPU" }
        Gauge { value: SysStats.ram; label: "RAM"; detail: SysStats.ramUsedGb.toFixed(1) + " / " + SysStats.ramTotalGb.toFixed(1) + " GB" }
        Gauge { value: SysStats.battery; label: SysStats.charging ? "BAT +" : "BAT"
                color: SysStats.battery < 0.2 ? Theme.danger : Theme.accent2 }
        Item {
            width: 96; height: 96
            Column {
                anchors.centerIn: parent; spacing: 4
                Repeater {
                    model: 6
                    Rectangle {
                        required property int index
                        width: 70; height: 3; color: Theme.alpha(Theme.accent, 0.15)
                        Rectangle {
                            height: parent.height; color: Theme.accent
                            width: parent.width * (0.2 + 0.8 * Math.abs(Math.sin(t.v + index)))
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
                        }
                    }
                }
                Text { text: "NET // SYNC"; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 2 }
            }
            Timer { id: t; property real v: 0; interval: 600; running: root.visible; repeat: true; onTriggered: v += 0.7 + Math.random() }
        }
    }

    Text {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 10; anchors.horizontalCenter: parent.horizontalCenter
        text: root.host; color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 10; font.letterSpacing: 1
    }
}
