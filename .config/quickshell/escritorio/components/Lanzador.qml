import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs

// Lanzador (Super+D): C:\> y lo que escribas. Primero las apps que empiezan así, luego las que lo contienen.
// Vacío, muestra las últimas abiertas. ↑ ↓ para moverse, Enter abre, Esc cierra.
Item {
    id: root
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    property var recientes: []
    property int elegido: 0

    readonly property var resultados: {
        const q = campo.text.trim().toLowerCase();
        if (!q) {
            const r = recientes.map(id => apps.find(a => a.id === id)).filter(a => !!a);
            return r.concat(apps.filter(a => recientes.indexOf(a.id) < 0)).slice(0, 8);
        }
        const empieza = [], contiene = [];
        for (const a of apps) {
            const n = a.name.toLowerCase();
            if (n.startsWith(q)) empieza.push(a);
            else if (n.includes(q) || (a.genericName || "").toLowerCase().includes(q)) contiene.push(a);
        }
        return empieza.concat(contiene).slice(0, 8);
    }
    onResultadosChanged: elegido = 0

    function abrir(a) {
        if (!a) return;
        a.execute();
        recientes = [a.id].concat(recientes.filter(x => x !== a.id)).slice(0, 8);
        archivo.setText(JSON.stringify(recientes));
        Estado.cerrar();
    }

    FileView {
        id: archivo
        path: Quickshell.env("HOME") + "/.cache/escritorio/recientes.json"
        printErrors: false
        blockWrites: true   // se escribe justo antes de cerrarse
        onLoaded: { try { root.recientes = JSON.parse(text()); } catch (e) {} }
    }

    VentanaW98 {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -80
        width: 520
        titulo: "EJECUTAR"
        cerrable: true
        onCerrada: Estado.cerrar()

        // C:\> campo
        Row {
            width: parent.width
            spacing: 6
            Text { text: "C:\\>"; color: "#b6f06a"; font.family: Theme.fontMono; font.pixelSize: 16; font.bold: true }
            TextInput {
                id: campo
                width: parent.width - 60
                focus: true
                color: Theme.text; selectionColor: Theme.accent
                font.family: Theme.fontMono; font.pixelSize: 16
                cursorDelegate: Rectangle {
                    width: 9; color: "#b6f06a"
                    property bool encendido: true
                    opacity: encendido ? 1 : 0
                    Timer { interval: 530; repeat: true; running: !Estado.ligero; onTriggered: parent.encendido = !parent.encendido }
                }
                Keys.onEscapePressed: Estado.cerrar()
                Keys.onUpPressed: root.elegido = Math.max(0, root.elegido - 1)
                Keys.onDownPressed: root.elegido = Math.min(root.resultados.length - 1, root.elegido + 1)
                Keys.onReturnPressed: root.abrir(root.resultados[root.elegido])
                Keys.onEnterPressed: root.abrir(root.resultados[root.elegido])
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.3) }

        Repeater {
            model: root.resultados
            Rectangle {
                required property var modelData
                required property int index
                readonly property bool activo: index === root.elegido
                width: parent.width; height: 30
                color: activo ? Theme.alpha("#b6f06a", 0.14) : "transparent"
                Row {
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12; text: parent.parent.activo ? "▶" : ""
                        color: "#b6f06a"; font.family: Theme.fontMono; font.pixelSize: 12
                    }
                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 22
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: parent.parent.activo ? Theme.accentBright : Theme.text
                        font.family: Theme.fontUi; font.pixelSize: 14
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.elegido = index
                    onClicked: root.abrir(modelData)
                }
            }
        }

        Text {
            visible: root.resultados.length === 0
            text: "No se encuentra el comando."
            color: Theme.danger; font.family: Theme.fontMono; font.pixelSize: 12
        }
    }
}
