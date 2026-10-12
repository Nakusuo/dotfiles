import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs

// OSD de volumen y brillo con las letras de videocámara: VOL ▮▮▮▮▮▮▯▯▯▯ 60%
// El volumen llega de PipeWire y el brillo cuando KDE avisa por D-Bus; nada se sondea.
Scope {
    id: osd
    property string tipo: ""      // "VOL" | "BRI" | "" (oculto)
    property real valor: 0
    property bool mudo: false
    property bool listo: false    // al arrancar llegan los valores iniciales: no se muestran

    function mostrar(t, v, m) {
        if (!listo) return;
        tipo = t; valor = Math.max(0, Math.min(1, v)); mudo = m;
        ocultar.restart();
    }
    Timer { interval: 2000; running: true; onTriggered: osd.listo = true }
    Timer { id: ocultar; interval: 1500; onTriggered: osd.tipo = "" }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    Connections {
        target: osd.audio
        ignoreUnknownSignals: true
        function onVolumeChanged() { osd.mostrar("VOL", osd.audio.volume, osd.audio.muted); }
        function onMutedChanged() { osd.mostrar("VOL", osd.audio.volume, osd.audio.muted); }
    }

    Process {
        id: leerBrillo
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do echo $(cat $d/brightness) $(cat $d/max_brightness); break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ").map(Number);
                if (p[1] > 0) osd.mostrar("BRI", p[0] / p[1], false);
            }
        }
    }
    Process {
        running: true
        command: ["dbus-monitor", "--session",
                  "type='signal',path_namespace='/org/kde/ScreenBrightness'",
                  "type='signal',member='brightnessChanged'"]
        stdout: SplitParser { onRead: data => { if (data.indexOf("member=") >= 0) leerBrillo.running = true; } }
    }

    PanelWindow {
        anchors.bottom: true
        margins.bottom: 100          // por encima del dock
        implicitWidth: 380
        implicitHeight: 36
        visible: osd.tipo !== ""
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "verdetech-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.bg, 0.8)
            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.4)

            Row {
                anchors.centerIn: parent
                spacing: 10
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.alerta }
                TextoNvg { text: osd.tipo; font.pixelSize: 16; font.bold: true }
                TextoNvg {
                    readonly property int n: Math.round(osd.valor * 10)
                    text: osd.mudo ? "MUTE" : "▮".repeat(n) + "▯".repeat(10 - n)
                    color: osd.mudo ? Theme.alerta : "#b6f06a"
                    font.pixelSize: 16
                }
                TextoNvg { visible: !osd.mudo; text: Math.round(osd.valor * 100) + "%"; font.pixelSize: 16 }
            }
        }
    }
}
