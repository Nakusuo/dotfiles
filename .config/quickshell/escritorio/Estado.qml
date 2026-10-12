pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // Lo que está abierto encima: "" | "panel" | "lanzador" | "apagado"
    property string abierto: ""
    // Modo ligero (Super+Shift+G): sin animaciones ni parpadeos. ligero.sh lo cambia por IPC
    property bool ligero: false
    // Últimas notificaciones de la sesión (solo en memoria)
    property var avisos: []

    function alternar(que) { abierto = abierto === que ? "" : que; }
    function cerrar() { abierto = ""; }
    function anotar(n) {
        avisos = [{ app: n.appName, titulo: n.summary, texto: n.body,
                    hora: Qt.formatTime(new Date(), "hh:mm") }].concat(avisos).slice(0, 10);
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/modo-ligero"
        printErrors: false
        onLoaded: root.ligero = true
    }
}
