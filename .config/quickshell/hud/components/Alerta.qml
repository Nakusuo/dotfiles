import QtQuick
import qs
import qs.services

// Ventana roja «警告 WARNING» que aparece sola cuando algo va mal
// (batería baja sin cargar, CPU o RAM al tope)
HudFrame {
    id: root
    width: 280; height: 118
    title: "警告  WARNING"
    tituloA: "#6b1a1f"
    tituloB: Theme.alerta

    readonly property string motivo:
        SysStats.battery > 0 && SysStats.battery < 0.2 && !SysStats.charging ? "Batería al " + Math.round(SysStats.battery * 100) + "%. Conecta el cargador."
        : SysStats.cpu > 0.9 ? "CPU al " + Math.round(SysStats.cpu * 100) + "%. Algo está exigiendo de más."
        : SysStats.ram > 0.9 ? "RAM al " + Math.round(SysStats.ram * 100) + "%. Cierra algo."
        : ""
    visible: motivo !== ""

    Row {
        x: 12; spacing: 12
        Rectangle {   // el círculo rojo con la × de los errores de Windows
            width: 34; height: 34; radius: 17
            color: Theme.alerta
            border.width: 2; border.color: "#ffffff"
            Text { anchors.centerIn: parent; text: "×"; color: "#ffffff"; font.pixelSize: 24; font.bold: true }
            SequentialAnimation on opacity { loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
        }
        Text {
            width: root.width - 80
            text: root.motivo
            wrapMode: Text.WordWrap
            color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 12
        }
    }
}
