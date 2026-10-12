import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Clima de wttr.in con caché: solo se descarga al abrir el panel y si el dato tiene más de 30 min.
// Sin red se queda con el último dato y avisa NO SIGNAL.
Column {
    id: root
    spacing: 2
    readonly property string archivo: Quickshell.env("HOME") + "/.cache/escritorio/clima.json"
    property var datos: null
    property bool sinSenal: false

    FileView {
        path: root.archivo
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.datos = JSON.parse(text()); } catch (e) {} }
    }

    Process {
        running: true
        command: ["sh", "-c", "f=\"$1\"; mkdir -p \"$(dirname \"$f\")\"; [ -n \"$(find \"$f\" -mmin -30 2>/dev/null)\" ] && exit 0; curl -fsm 15 'https://wttr.in/?format=j1&lang=es' -o \"$f.tmp\" && mv \"$f.tmp\" \"$f\"", "sh", root.archivo]
        onExited: code => root.sinSenal = code !== 0
    }

    readonly property var ahora: datos && datos.current_condition ? datos.current_condition[0] : null
    readonly property var dia: datos && datos.weather ? datos.weather[0] : null

    Row {
        spacing: 10
        Text {
            text: root.ahora ? root.ahora.temp_C + "°" : "--°"
            color: "#b6f06a"; font.family: Theme.fontMono; font.pixelSize: 26; font.bold: true
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: root.ahora ? ((root.ahora.lang_es && root.ahora.lang_es[0].value) || root.ahora.weatherDesc[0].value) : "Sin datos"
                color: Theme.text; font.family: Theme.fontUi; font.pixelSize: 12
            }
            Text {
                text: root.dia ? "MIN " + root.dia.mintempC + "°  MAX " + root.dia.maxtempC + "°" : ""
                color: Theme.muted; font.family: Theme.fontMono; font.pixelSize: 11
            }
        }
    }
    Text {
        visible: root.sinSenal
        text: "NO SIGNAL"; color: Theme.alerta; font.family: Theme.fontMono; font.pixelSize: 11; font.bold: true
    }
}
