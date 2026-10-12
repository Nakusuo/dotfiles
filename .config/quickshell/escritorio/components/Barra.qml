import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs

// Barra lateral izquierda de 44 px: ● REC, escritorios, reloj, bandeja, estado y ⏻.
// Nada sondea: KWin y NetworkManager avisan de sus cambios; el reloj va por minutos.
PanelWindow {
    id: barra
    anchors { left: true; top: true; bottom: true }
    implicitWidth: 44
    exclusiveZone: 44
    color: Theme.alpha(Theme.bg, 0.92)
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "verdetech-barra"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.alpha(Theme.accent, 0.35) }

    component Icono: Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.accent; font.family: Theme.fontIcons; font.pixelSize: 16
    }
    component Mini: Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 9
    }

    // ---------- datos ----------
    SystemClock { id: reloj; precision: SystemClock.Minutes }

    // Escritorios de KWin: se leen al arrancar y cada vez que KWin avisa de un cambio
    property int escritorio: 1
    property int escritorios: 4
    Process {
        id: leerEscritorios
        running: true
        command: ["sh", "-c", "qdbus6 org.kde.KWin /KWin org.kde.KWin.currentDesktop; qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n").map(Number);
                if (l[0] > 0) barra.escritorio = l[0];
                if (l[1] > 0) barra.escritorios = l[1];
            }
        }
    }
    Process {
        running: true
        command: ["dbus-monitor", "--session", "type='signal',interface='org.kde.KWin.VirtualDesktopManager'"]
        stdout: SplitParser { onRead: data => { if (data.indexOf("member=") >= 0) leerEscritorios.running = true; } }
    }

    // Red: -1 sin conexión, 0 por cable, 1..100 potencia del wifi (sin volver a escanear)
    property int senal: -1
    Process {
        id: leerRed
        running: true
        command: ["sh", "-c", "case $(nmcli -t -f STATE g) in connected*) w=$(nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no 2>/dev/null | grep '^yes' | cut -d: -f2); echo ${w:-0};; *) echo -1;; esac"]
        stdout: StdioCollector { onStreamFinished: { const n = parseInt(text); barra.senal = isNaN(n) ? -1 : n; } }
    }
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: _ => leerRed.running = true }
    }
    Timer { interval: 120000; running: true; repeat: true; onTriggered: leerRed.running = true }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null

    readonly property var bateria: UPower.displayDevice
    readonly property real carga: {
        const p = bateria ? bateria.percentage : 0;
        return p > 1 ? p / 100 : p;
    }

    // ---------- arriba ----------
    Column {
        anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
        spacing: 14

        // ● REC: abre el panel
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40; height: 30
            property bool encendido: true
            Timer {
                interval: 1000; repeat: true; running: !Estado.ligero
                onTriggered: parent.encendido = !parent.encendido
                onRunningChanged: if (!running) parent.encendido = true
            }
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                width: 10; height: 10; radius: 5
                color: Theme.alerta; opacity: parent.encendido ? 1 : 0.15
            }
            Text {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                text: "REC"; color: Estado.abierto === "panel" ? Theme.accentBright : Theme.alerta
                font.family: Theme.fontMono; font.pixelSize: 10; font.bold: true
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Estado.alternar("panel") }
        }

        // escritorios virtuales
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: barra.escritorios
                Rectangle {
                    required property int index
                    readonly property bool activo: index + 1 === barra.escritorio
                    width: 28; height: 20
                    color: activo ? "#b6f06a" : "transparent"
                    border.width: 1; border.color: activo ? "#b6f06a" : Theme.alpha(Theme.accent, 0.4)
                    Text {
                        anchors.centerIn: parent
                        text: (index < 9 ? "0" : "") + (index + 1)
                        color: parent.activo ? Theme.bg : Theme.muted
                        font.family: Theme.fontMono; font.pixelSize: 11; font.bold: parent.activo
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["qdbus6", "org.kde.KWin", "/KWin", "org.kde.KWin.setCurrentDesktop", String(index + 1)])
                    }
                }
            }
        }

        // reloj vertical
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(reloj.date, "hh"); color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 18; font.bold: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(reloj.date, "mm"); color: Theme.accent; font.family: Theme.fontMono; font.pixelSize: 18 }
            Mini { text: Qt.formatDate(reloj.date, "dd·MM") }
        }
    }

    // ---------- abajo ----------
    Column {
        anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        spacing: 12

        // bandeja del sistema
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Repeater {
                model: SystemTray.items
                IconImage {
                    id: icono
                    required property var modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: 18
                    source: modelData.icon
                    opacity: 0.85
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton && icono.modelData.hasMenu) {
                                const p = icono.mapToItem(null, 0, 0);
                                icono.modelData.display(barra, 46, p.y);
                            } else {
                                icono.modelData.activate();
                            }
                        }
                    }
                }
            }
        }

        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 24; height: 1; color: Theme.alpha(Theme.accent, 0.3) }

        // volumen (la rueda lo cambia, el clic silencia)
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            Icono {
                text: !barra.audio || barra.audio.muted ? "󰖁" : "󰕾"
                color: barra.audio && barra.audio.muted ? Theme.danger : Theme.accent
                MouseArea {
                    anchors { fill: parent; margins: -6 }
                    onClicked: if (barra.audio) barra.audio.muted = !barra.audio.muted
                    onWheel: wheel => {
                        if (!barra.audio) return;
                        barra.audio.volume = Math.max(0, Math.min(1, barra.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                    }
                }
            }
            Mini { text: barra.audio ? Math.round(barra.audio.volume * 100) : "--" }
        }

        // red
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            Icono {
                text: barra.senal < 0 ? "󰖪" : barra.senal === 0 ? "󰈀" : "󰖩"
                color: barra.senal < 0 ? Theme.danger : Theme.accent
            }
            Mini { text: barra.senal < 0 ? "OFF" : barra.senal === 0 ? "LAN" : barra.senal + "%" }
        }

        // batería (solo si es laptop)
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: barra.bateria && barra.bateria.isLaptopBattery
            Icono {
                text: !UPower.onBattery ? "󰂄" : barra.carga > 0.6 ? "󰁹" : barra.carga > 0.3 ? "󰁾" : "󰁻"
                color: UPower.onBattery && barra.carga < 0.15 ? Theme.danger : Theme.accent
            }
            Mini { text: Math.round(barra.carga * 100) + "%" }
        }

        // apagado
        Icono {
            text: "⏻"
            color: Estado.abierto === "apagado" ? Theme.alerta : Theme.accent
            font.pixelSize: 18
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Estado.alternar("apagado") }
        }
    }
}
