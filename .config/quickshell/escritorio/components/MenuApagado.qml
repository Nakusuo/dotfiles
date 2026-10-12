import QtQuick
import Quickshell
import qs

// Menú de ⏻, pegado abajo a la izquierda junto a la barra
Item {
    function hacer(cmd) { Estado.cerrar(); Quickshell.execDetached(["sh", "-c", cmd]); }

    VentanaW98 {
        x: 6
        y: parent.height - height - 6
        width: 200
        titulo: "APAGAR.EXE"
        cerrable: true
        onCerrada: Estado.cerrar()

        Boton { width: parent.width; texto: "Bloquear"; onPulsado: hacer("loginctl lock-session") }
        Boton { width: parent.width; texto: "Cerrar sesión"; onPulsado: hacer("qdbus6 org.kde.Shutdown /Shutdown logout || loginctl terminate-session $XDG_SESSION_ID") }
        Boton { width: parent.width; texto: "Reiniciar"; onPulsado: hacer("qdbus6 org.kde.Shutdown /Shutdown logoutAndReboot || systemctl reboot") }
        Boton { width: parent.width; texto: "Apagar"; rojo: true; onPulsado: hacer("qdbus6 org.kde.Shutdown /Shutdown logoutAndShutdown || systemctl poweroff") }
    }
}
