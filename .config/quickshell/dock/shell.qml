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

    // Apps fijadas (nombre del archivo .desktop, sin ".desktop"). Se guardan en fijadas.json
    // para que «Anclar / Desanclar» del menú del clic derecho sobreviva a los reinicios.
    property var fijadas: []
    FileView {
        id: archivoFijadas
        path: Quickshell.shellDir + "/fijadas.json"
        blockLoading: true
        onLoaded: {
            try { root.fijadas = JSON.parse(text()); } catch (e) { console.warn("fijadas.json ilegible:", e); }
        }
    }
    function estaFijada(id) { return fijadas.some(f => f.toLowerCase() === id.toLowerCase()); }
    function alternarFijada(id) {
        const nuevas = estaFijada(id) ? fijadas.filter(f => f.toLowerCase() !== id.toLowerCase())
                                      : fijadas.concat([id]);
        fijadas = nuevas;
        archivoFijadas.setText(JSON.stringify(nuevas) + "\n");
    }
    onFijadasChanged: armarItems()

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
    property var escritorios: [] // escritorios virtuales, para «Mover a escritorio»
    readonly property var aqui: ventanas.filter(w => w.aqui)
    property bool tapa: false

    function claveDe(w) {
        let k = (w.app || w.cls || "").toLowerCase();
        if (k.startsWith("dash-")) k = "alacritty";   // ventanas del dashboard
        return k;
    }

    // Solo cambia cuando cambia la lista de íconos (no con cada movimiento de ventana):
    // si no, el Repeater recrea los íconos a cada rato y se pierden los clics.
    property var items: []
    onAquiChanged: armarItems()
    Component.onCompleted: armarItems()
    function armarItems() {
        const out = [], vistos = {};
        for (const id of fijadas) {
            vistos[id.toLowerCase()] = true;
            out.push({ clave: id.toLowerCase(), id: id });
        }
        for (const w of aqui) {
            const k = claveDe(w);
            if (!k) continue;   // ventanas sin app ni clase (no se pueden identificar)
            if (!vistos[k]) { vistos[k] = true; out.push({ clave: k, id: w.app || w.cls }); }
        }
        if (JSON.stringify(out) !== JSON.stringify(items)) items = out;
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
                    if (d.escritorios) root.escritorios = d.escritorios;
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) reinicio.start()
    }
    Timer { id: reinicio; interval: 2000; onTriggered: puente.running = true }

    // Minimizar / cerrar: KWin no las ofrece por DBus, las aplica accion.py con un script de un solo uso
    function accionVentana(accion, w, extra) {
        Quickshell.execDetached(["python3", Quickshell.shellDir + "/accion.py", accion, w.id].concat(extra ? [extra] : []));
    }

    // Opción del menú del clic derecho
    component Opcion: Rectangle {
        id: op
        required property string texto
        property bool peligro: false
        property bool sangria: false     // opción dentro de un submenú
        property int marcada: -1         // -1 sin casilla, 0 sin marcar, 1 marcada
        property int submenu: -1         // -1 no es submenú, 0 cerrado, 1 abierto
        signal elegido()
        width: 240; height: 30; radius: 7
        color: zonaOp.containsMouse ? Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.18) : "transparent"
        Text {
            anchors { left: parent.left; leftMargin: op.sangria ? 26 : 12; verticalCenter: parent.verticalCenter }
            text: (op.marcada === 1 ? "✓ " : op.marcada === 0 ? "   " : "") + op.texto
            color: op.peligro ? "#e38b7f" : root.texto
            font.family: "Rajdhani"; font.pixelSize: 15; font.weight: Font.DemiBold
        }
        Text {
            visible: op.submenu >= 0
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: op.submenu === 1 ? "▾" : "▸"
            color: root.acento; font.pixelSize: 13
        }
        MouseArea { id: zonaOp; anchors.fill: parent; hoverEnabled: true; onClicked: op.elegido() }
    }
    component Separador: Rectangle {
        width: 240; height: 9; color: "transparent"
        Rectangle { anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.25) }
    }

    // Activar una ventana (execDetached: dos clics seguidos no se pisan como con un Process compartido)
    function activar(w) {
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.kde.KWin",
                                 "--object-path", "/WindowsRunner", "--method", "org.kde.krunner1.Run", "0_" + w.id, ""]);
    }

    // Para probar el menú sin ratón: qs -c dock ipc call dock menu brave-origin
    signal pedirMenu(string id)
    IpcHandler {
        target: "dock"
        function menu(id: string): void { root.pedirMenu(id); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: ventana
            required property var modelData
            screen: modelData

            // Alto de la zona del dock (espacio para que crezcan los íconos y salga el nombre)
            readonly property int altoDock: root.maximo + root.relleno * 2 + 40
            // La ventana es más alta para que el menú del clic derecho quepa DENTRO de ella.
            // Es transparente y la máscara deja pasar los clics fuera de la barra y del menú.
            readonly property int altoMenu: 640

            anchors { bottom: true; left: true; right: true }
            implicitHeight: altoDock + altoMenu
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "verdetech-dock"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // El cursor está sobre la franja del dock (no sobre el menú)
            readonly property bool enDock: raton.hovered && raton.point.position.y >= height - altoDock
            readonly property bool menuAbierto: menuApp !== null
            readonly property bool visible_: !root.tapa || zona.hovered || enDock || menuAbierto
            readonly property int anchoBase: root.items.length * (root.base + root.espacio) - root.espacio

            // Solo la barra (o la franja del borde cuando está escondido) y el menú reciben el ratón
            mask: Region {
                item: ventana.visible_ ? (ventana.enDock ? zonaCrecida : zonaBarra) : franja
                Region { item: ventana.menuAbierto ? caja : null; intersection: Intersection.Combine }
            }

            // ---------- Menú del clic derecho ----------
            property var menuApp: null      // { id, clave } de la app del menú
            property real menuX: 0          // centro del ícono, en coordenadas de la ventana
            property bool verEscritorios: false
            property bool verMas: false
            readonly property var menuEntrada: menuApp && DesktopEntries.applications.values.length >= 0
                                               ? DesktopEntries.heuristicLookup(menuApp.id) : null
            readonly property var menuSuyas: menuApp ? root.aqui.filter(w => root.claveDe(w) === menuApp.clave) : []
            readonly property var menuPrimera: menuSuyas.length ? menuSuyas[0] : null

            function abrirMenu(item) {
                const p = item.mapToItem(ventana.contentItem, item.width / 2, 0);
                menuX = p.x;
                verEscritorios = false; verMas = false;
                menuTocado = cursorCerca;
                menuApp = { id: item.modelData.id, clave: item.modelData.clave };
            }
            function cerrarMenu() { menuApp = null; verEscritorios = false; verMas = false; }
            // Las acciones de ventana se aplican a todas las ventanas de la app en este escritorio
            function aTodas(accion, extra) { menuSuyas.forEach(w => root.accionVentana(accion, w, extra)); cerrarMenu(); }

            Connections {
                target: root
                function onPedirMenu(id) {
                    for (let i = 0; i < iconos.count; i++) {
                        const it = iconos.itemAt(i);
                        if (it && it.modelData.id.toLowerCase() === id.toLowerCase()) { ventana.abrirMenu(it); return; }
                    }
                }
            }

            // Se cierra solo cuando el cursor, después de haber estado sobre el dock o el menú, se aleja de ambos
            property bool menuTocado: false
            readonly property bool cursorCerca: raton.hovered || sobreMenu.hovered
            onCursorCercaChanged: if (cursorCerca && menuAbierto) menuTocado = true
            Timer {
                interval: 900
                running: ventana.menuAbierto && ventana.menuTocado && !ventana.cursorCerca
                onTriggered: ventana.cerrarMenu()
            }

            Rectangle {
                id: caja
                visible: ventana.menuAbierto
                z: 10
                width: lista.width + 12; height: lista.height + 12
                x: Math.max(8, Math.min(ventana.width - width - 8, ventana.menuX - width / 2))
                y: ventana.height - (root.maximo + root.relleno + 20) - height
                radius: 12
                color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, 0.97)
                border.width: 1; border.color: Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.6)
                HoverHandler { id: sobreMenu }

                Column {
                    id: lista
                    x: 6; y: 6
                    Text {
                        width: 240; height: 28
                        leftPadding: 12; verticalAlignment: Text.AlignVCenter
                        text: ventana.menuEntrada?.name ?? ventana.menuApp?.id ?? ""
                        color: root.acento; elide: Text.ElideRight
                        font.family: "Rajdhani"; font.pixelSize: 14; font.weight: Font.Bold
                    }

                    // Acciones propias de la app, leídas de su .desktop («Nueva ventana de incógnito», etc.)
                    Repeater {
                        model: ventana.menuEntrada?.actions ?? []
                        Opcion {
                            required property var modelData
                            texto: modelData.name
                            onElegido: { modelData.execute(); ventana.cerrarMenu(); }
                        }
                    }
                    Separador { visible: (ventana.menuEntrada?.actions ?? []).length > 0 }

                    Opcion {
                        texto: ventana.menuSuyas.length ? "Iniciar nueva instancia" : "Abrir"
                        visible: !!ventana.menuEntrada
                        onElegido: { ventana.menuEntrada.execute(); ventana.cerrarMenu(); }
                    }
                    Opcion {
                        texto: "Mover a escritorio"
                        visible: !!ventana.menuPrimera && root.escritorios.length > 1
                        submenu: ventana.verEscritorios ? 1 : 0
                        onElegido: ventana.verEscritorios = !ventana.verEscritorios
                    }
                    Repeater {
                        model: ventana.verEscritorios ? root.escritorios : []
                        Opcion {
                            required property var modelData
                            required property int index
                            sangria: true
                            texto: (index + 1) + ". " + modelData.nombre
                            marcada: (ventana.menuPrimera?.escritorios ?? []).includes(modelData.id) ? 1 : 0
                            onElegido: ventana.aTodas("escritorio", modelData.id)
                        }
                    }
                    Opcion {
                        visible: ventana.verEscritorios
                        sangria: true
                        texto: "Todos los escritorios"
                        marcada: ventana.menuPrimera && ventana.menuPrimera.escritorios.length === 0 ? 1 : 0
                        onElegido: ventana.aTodas("todos")
                    }
                    Opcion {
                        texto: "Más"
                        visible: !!ventana.menuPrimera
                        submenu: ventana.verMas ? 1 : 0
                        onElegido: ventana.verMas = !ventana.verMas
                    }
                    Column {
                        visible: ventana.verMas
                        Opcion { sangria: true; texto: "Mover"; onElegido: ventana.aTodas("mover") }
                        Opcion { sangria: true; texto: "Redimensionar"; onElegido: ventana.aTodas("redimensionar") }
                        Opcion { sangria: true; texto: "Minimizar"; onElegido: ventana.aTodas("minimizar") }
                        Opcion { sangria: true; texto: "Maximizar / restaurar"; onElegido: ventana.aTodas("maximizar") }
                        Opcion { sangria: true; texto: "Mantener por encima de otras"; marcada: ventana.menuPrimera?.encima ? 1 : 0; onElegido: ventana.aTodas("encima") }
                        Opcion { sangria: true; texto: "Pantalla completa"; marcada: ventana.menuPrimera?.completa ? 1 : 0; onElegido: ventana.aTodas("completa") }
                    }
                    Opcion {
                        texto: "Anclar al dock"
                        marcada: ventana.menuApp && root.estaFijada(ventana.menuApp.id) ? 1 : 0
                        onElegido: { root.alternarFijada(ventana.menuApp.id); ventana.cerrarMenu(); }
                    }

                    Separador { visible: !!ventana.menuPrimera }
                    Opcion {
                        texto: ventana.menuSuyas.length > 1 ? "Cerrar todas (" + ventana.menuSuyas.length + ")" : "Cerrar"
                        peligro: true
                        visible: !!ventana.menuPrimera
                        onElegido: ventana.aTodas("cerrar")
                    }
                }
            }

            // ---------- Zonas que reciben el ratón ----------
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
                width: barra.width + root.maximo; height: ventana.altoDock
            }

            // ---------- Barra e íconos ----------
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
                        id: iconos
                        model: root.items

                        Item {
                            id: icono
                            required property var modelData
                            required property int index

                            // La lista de apps carga en segundo plano: al mencionar "applications"
                            // la búsqueda se repite cuando termina de cargar (antes quedaba vacía y el clic no hacía nada)
                            readonly property var entrada: DesktopEntries.applications.values.length >= 0
                                                           ? DesktopEntries.heuristicLookup(modelData.id) : null
                            readonly property var suyas: root.aqui.filter(w => root.claveDe(w) === modelData.clave)
                            readonly property bool activa: suyas.some(w => w.activa)

                            // Efecto lupa: distancia (en íconos) entre el cursor y este ícono.
                            // Con el menú abierto la lupa se queda quieta para que el ícono no se mueva debajo.
                            readonly property real distancia: {
                                if (!ventana.enDock || ventana.menuAbierto) return 99;
                                const izquierda = (ventana.width - ventana.anchoBase) / 2;
                                const centro = izquierda + index * (root.base + root.espacio) + root.base / 2;
                                return (raton.point.position.x - centro) / (root.base + root.espacio);
                            }
                            readonly property real lupa: Math.exp(-(distancia * distancia) / (2 * root.alcance * root.alcance / 2))

                            width: root.base + (root.maximo - root.base) * lupa
                            height: width
                            y: parent.height - height
                            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                            // Tamaño fijo (el máximo) y solo se escala: si cambiara de tamaño, el ícono
                            // se volvería a cargar en cada paso del efecto lupa y parpadearía/desaparecería
                            Image {
                                width: root.maximo; height: root.maximo
                                anchors.centerIn: parent
                                scale: icono.width / root.maximo
                                source: Quickshell.iconPath(icono.entrada?.icon ?? icono.modelData.id, "application-x-executable")
                                sourceSize: Qt.size(root.maximo, root.maximo)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
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

                            // Nombre de la app al pasar el cursor (no con el menú abierto)
                            Rectangle {
                                visible: area.containsMouse && !ventana.menuAbierto
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
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                onClicked: ev => {
                                    if (ev.button === Qt.RightButton) {
                                        // Clic derecho en el mismo ícono con el menú abierto: lo cierra
                                        if (ventana.menuAbierto && ventana.menuApp.clave === icono.modelData.clave) ventana.cerrarMenu();
                                        else ventana.abrirMenu(icono);
                                        return;
                                    }
                                    ventana.cerrarMenu();
                                    const s = icono.suyas;
                                    // Abierta solo en otro escritorio (p. ej. Spotify, que no abre una segunda ventana): ir a ella
                                    const otra = root.ventanas.find(w => root.claveDe(w) === icono.modelData.clave);
                                    if (ev.button === Qt.LeftButton && s.length === 0 && otra) {
                                        root.activar(otra);
                                        return;
                                    }
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
