import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Dock "Verde Tech" con efecto lupa estilo Mac.
//  - Las ventanas abiertas llegan desde KWin a través de puente.py (ventanas.js)
//  - Cada escritorio va por su cuenta: solo cuentan las ventanas del escritorio actual
//  - Clic: abre la app, o la trae al frente; si ya está al frente, pasa a su siguiente ventana
//  - Clic central: abre otra ventana de la app
//  - Se esconde cuando una ventana lo tapa; aparece al llevar el cursor al borde de abajo
ShellRoot {
    id: root

    // Apps fijadas (nombre del archivo .desktop, sin ".desktop")
    property var fijadas: ["brave-origin", "org.kde.dolphin", "antigravity-ide", "org.kde.konsole", "spotify", "Alacritty"]

    // Tamaños (px)
    readonly property int base: 40        // ícono en reposo
    readonly property int maximo: 68      // ícono bajo el cursor
    readonly property int espacio: 8      // separación entre íconos
    readonly property int relleno: 8      // borde interior de la barra
    readonly property real alcance: 1.6   // cuántos íconos vecinos crecen también

    // Paleta Verde Tech
    readonly property color acento: "#6cc196"
    readonly property color acentoClaro: "#8fd3ae"
    readonly property color fondo: "#0a0f0c"
    readonly property color texto: "#cfdcd4"

    property var ventanas: []   // todas las ventanas (de todos los escritorios)
    readonly property var aqui: ventanas.filter(w => w.aqui)
    property bool tapa: false

    function claveDe(w) {
        let k = (w.app || w.cls || "").toLowerCase();
        if (k.startsWith("dash-")) k = "alacritty";   // ventanas del dashboard
        return k;
    }

    readonly property var items: {
        const out = [], vistos = {};
        for (const id of fijadas) {
            vistos[id.toLowerCase()] = true;
            out.push({ clave: id.toLowerCase(), id: id });
        }
        for (const w of aqui) {
            const k = claveDe(w);
            if (!vistos[k]) { vistos[k] = true; out.push({ clave: k, id: w.app || w.cls }); }
        }
        return out;
    }

    Process {
        id: puente
        running: true
        command: ["python3", Quickshell.shellDir + "/puente.py"]
        stdout: SplitParser {
            onRead: linea => {
                try {
                    const d = JSON.parse(linea);
                    root.ventanas = d.ventanas;
                    root.tapa = d.tapa;
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) reinicio.start()
    }
    Timer { id: reinicio; interval: 2000; onTriggered: puente.running = true }

    Process { id: activador }
    function activar(w) {
        activador.command = ["gdbus", "call", "--session", "--dest", "org.kde.KWin",
                             "--object-path", "/WindowsRunner", "--method", "org.kde.krunner1.Run", "0_" + w.id, ""];
        activador.running = true;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: ventana
            required property var modelData
            screen: modelData

            anchors { bottom: true; left: true; right: true }
            implicitHeight: root.maximo + root.relleno * 2 + 40   // espacio para crecer y para el nombre
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "verdetech-dock"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property bool visible_: !root.tapa || zona.hovered || raton.hovered
            readonly property int anchoBase: root.items.length * (root.base + root.espacio) - root.espacio

            // Solo la barra (o la franja del borde cuando está escondido) recibe el ratón
            mask: Region { item: visible_ ? (raton.hovered ? zonaCrecida : zonaBarra) : franja }

            Item {
                id: franja
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                width: barra.width; height: 3
                HoverHandler { id: zona }
            }
            Item {
                id: zonaBarra   // la barra más el margen de abajo
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                width: barra.width; height: barra.height + 6
            }
            Item {
                id: zonaCrecida
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                width: barra.width + root.maximo; height: parent.height
            }

            Item {
                id: contenido
                anchors.fill: parent
                transform: Translate {
                    y: ventana.visible_ ? 0 : root.base + root.relleno * 2 + 12
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                HoverHandler { id: raton }

                Rectangle {
                    id: barra
                    anchors { bottom: parent.bottom; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                    width: fila.width + root.relleno * 2
                    height: root.base + root.relleno * 2
                    radius: 14
                    color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, 0.78)
                    border.width: 1
                    border.color: Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.45)
                }

                Row {
                    id: fila
                    anchors { bottom: barra.bottom; bottomMargin: root.relleno; horizontalCenter: barra.horizontalCenter }
                    height: root.maximo
                    spacing: root.espacio

                    Repeater {
                        model: root.items

                        Item {
                            id: icono
                            required property var modelData
                            required property int index

                            readonly property var entrada: DesktopEntries.heuristicLookup(modelData.id)
                            readonly property var suyas: root.aqui.filter(w => root.claveDe(w) === modelData.clave)
                            readonly property bool activa: suyas.some(w => w.activa)

                            // Efecto lupa: distancia (en íconos) entre el cursor y este ícono
                            readonly property real distancia: {
                                if (!raton.hovered) return 99;
                                const izquierda = (ventana.width - ventana.anchoBase) / 2;
                                const centro = izquierda + index * (root.base + root.espacio) + root.base / 2;
                                return (raton.point.position.x - centro) / (root.base + root.espacio);
                            }
                            readonly property real lupa: Math.exp(-(distancia * distancia) / (2 * root.alcance * root.alcance / 2))

                            width: root.base + (root.maximo - root.base) * lupa
                            height: width
                            y: parent.height - height
                            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                            IconImage {
                                anchors.fill: parent
                                source: Quickshell.iconPath(icono.entrada?.icon ?? icono.modelData.id, "application-x-executable")
                                asynchronous: true
                            }

                            // Indicador de app abierta: punto; si está al frente, raya más larga
                            Rectangle {
                                visible: icono.suyas.length > 0
                                anchors { top: parent.bottom; topMargin: 2; horizontalCenter: parent.horizontalCenter }
                                width: icono.activa ? 14 : 5
                                height: 3; radius: 2
                                color: icono.activa ? root.acentoClaro : root.acento
                                Behavior on width { NumberAnimation { duration: 150 } }
                            }

                            // Nombre de la app al pasar el cursor
                            Rectangle {
                                visible: area.containsMouse
                                anchors { bottom: parent.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                                width: nombre.implicitWidth + 16; height: nombre.implicitHeight + 6
                                radius: 6
                                color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, 0.9)
                                border.width: 1; border.color: root.acento
                                Text {
                                    id: nombre
                                    anchors.centerIn: parent
                                    text: icono.entrada?.name ?? icono.modelData.id
                                    color: root.texto
                                    font.family: "Rajdhani"; font.pixelSize: 14; font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: ev => {
                                    const s = icono.suyas;
                                    if (ev.button === Qt.MiddleButton || s.length === 0) {
                                        icono.entrada?.execute();
                                        return;
                                    }
                                    const i = s.findIndex(w => w.activa);
                                    root.activar(s[(i + 1) % s.length]);   // sin activa: i = -1 -> la primera
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
