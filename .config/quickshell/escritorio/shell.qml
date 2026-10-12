//@ pragma IconTheme BeautyLine-Verde
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.components

// Escritorio Verde Tech NVG sobre KDE Plasma (pensado para la laptop vieja: nada se mueve ni mide si no se ve)
//  - barra lateral izquierda; ● REC o Super+S abre el panel (música, calendario, clima, sistema, avisos)
//  - Super+D: lanzador · ⏻: menú de apagado
//  - notificaciones tipo Windows 98 y OSD de volumen/brillo con letras de videocámara
// Se activa y se quita con escritorio.sh on|off
ShellRoot {
    IpcHandler {
        target: "escritorio"
        function panel(): void { Estado.alternar("panel"); }
        function lanzador(): void { Estado.alternar("lanzador"); }
        function ligero(modo: string): void { Estado.ligero = modo === "on"; }
    }

    Barra {}

    // Panel, lanzador y menú solo existen mientras están abiertos
    LazyLoader {
        active: Estado.abierto !== ""
        Emergente {}
    }

    Notificaciones {}
    Osd {}
}
