import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs

// Notificaciones como ventanas de Windows 98, arriba a la derecha. Máximo 3 a la vez: el resto espera.
// Urgentes: barra roja con 警告 y no se cierran solas.
Scope {
    NotificationServer {
        id: servidor
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: false
        keepOnReload: false
        onNotification: n => { n.tracked = true; Estado.anotar(n); }
    }

    PanelWindow {
        anchors { top: true; right: true }
        margins { top: 8; right: 8 }
        implicitWidth: 340
        implicitHeight: Math.max(1, pila.implicitHeight)
        color: "transparent"
        visible: servidor.trackedNotifications.values.length > 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "verdetech-avisos"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: pila
            width: parent.width
            spacing: 6

            Repeater {
                model: servidor.trackedNotifications.values.slice(0, 3)

                VentanaW98 {
                    id: aviso
                    required property var modelData
                    readonly property bool urgente: modelData.urgency === NotificationUrgency.Critical
                    width: parent.width
                    roja: urgente
                    titulo: (urgente ? "警告 " : "") + (modelData.appName || "Aviso")
                    cerrable: true
                    onCerrada: modelData.dismiss()

                    Timer {
                        running: !aviso.urgente
                        interval: aviso.modelData.expireTimeout > 0 ? aviso.modelData.expireTimeout * 1000 : 5000
                        onTriggered: aviso.modelData.expire()
                    }

                    Text {
                        width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                        text: aviso.modelData.summary
                        color: Theme.text; font.family: Theme.fontUi; font.pixelSize: 13; font.bold: true
                    }
                    Text {
                        width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight
                        visible: text.length > 0
                        text: aviso.modelData.body; textFormat: Text.PlainText
                        color: Theme.muted; font.family: Theme.fontUi; font.pixelSize: 12
                    }
                    Flow {
                        width: parent.width; spacing: 6
                        visible: aviso.modelData.actions.length > 0
                        Repeater {
                            model: aviso.modelData.actions
                            Boton {
                                required property var modelData
                                texto: modelData.text || "Abrir"
                                onPulsado: modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }
}
