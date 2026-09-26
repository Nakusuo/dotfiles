pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Visualizador de audio: cava en modo raw -> lista de alturas 0..1
Singleton {
    id: root
    property bool active: false
    property int bars: 28
    property var values: []

    Process {
        running: root.active
        command: ["cava", "-p", Quickshell.shellDir + "/cava.conf"]
        stdout: SplitParser {
            onRead: data => {
                const v = data.split(";").filter(s => s.length).map(s => parseInt(s) / 100);
                if (v.length) root.values = v;
            }
        }
        onRunningChanged: if (!running) root.values = []
    }
}
