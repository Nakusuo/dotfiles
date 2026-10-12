import QtQuick

// Login Verde Tech NVG: el fondo y2k, los textos de videocámara en las esquinas
// y una ventana Windows 98 para entrar. Contraseña mal: tiembla y sale 警告 ACCESO DENEGADO.
// Sin efectos ni animaciones en bucle (laptop vieja).
Rectangle {
    id: root
    width: 1366; height: 768
    color: "#0d1310"

    readonly property color lima: "#b6f06a"
    readonly property color verde: "#6cc196"
    readonly property color texto: "#cfdcd4"
    readonly property color tenue: "#7d9186"
    readonly property color rojo: "#d0443a"
    readonly property string mono: "JetBrainsMono Nerd Font"
    property int sesion: sessionModel.lastIndex
    property int segundos: 0
    property bool denegado: false

    Connections {
        target: sddm
        function onLoginFailed() {
            root.denegado = true;
            clave.text = "";
            clave.enfocar();
            temblor.start();
        }
    }

    Image {
        anchors.fill: parent
        source: config.background || "fondo.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    component Nvg: Text {
        color: root.lima; font.family: root.mono; font.pixelSize: 16
        style: Text.Outline; styleColor: "#80000000"
    }

    // ---------- esquinas de cámara ----------
    Column {
        x: 28; y: 18
        Nvg { text: "Standard NVG" }
        Nvg { text: "40° FOV"; font.pixelSize: 28 }
    }
    Row {
        anchors { right: parent.right; rightMargin: 28; top: parent.top; topMargin: 22 }
        spacing: 10
        Rectangle { width: 44; height: 26; color: root.rojo
            Text { anchors.centerIn: parent; text: "ALT"; color: "white"; font.family: root.mono; font.pixelSize: 16; font.bold: true } }
        Nvg { anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDate(new Date(), "dd.MM.yyyy") }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: { root.segundos++; hora.text = Qt.formatTime(new Date(), "hh:mm"); } }
    Nvg {
        id: hora
        anchors { left: parent.left; leftMargin: 28; bottom: parent.bottom; bottomMargin: 24 }
        text: Qt.formatTime(new Date(), "hh:mm"); font.pixelSize: 28
    }
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
        spacing: 8
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5; color: root.rojo }
        Text {
            readonly property int s: root.segundos
            text: "REC " + ("0" + Math.floor(s / 3600)).slice(-2) + ":" + ("0" + Math.floor(s % 3600 / 60)).slice(-2) + ":" + ("0" + s % 60).slice(-2)
            color: root.rojo; font.family: root.mono; font.pixelSize: 22; font.bold: true
        }
    }

    // ---------- ventana Windows 98 ----------
    component Bisel: Item {
        property color claro: "#8fd3ae"
        property color oscuro: "#050806"
        property bool hundido: false
        anchors.fill: parent
        Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 2; color: parent.hundido ? parent.oscuro : parent.claro }
        Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 2; color: parent.hundido ? parent.oscuro : parent.claro }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 2; color: parent.hundido ? parent.claro : parent.oscuro }
        Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 2; color: parent.hundido ? parent.claro : parent.oscuro }
    }
    component Barra: Rectangle {
        property string titulo
        property bool roja: false
        x: 3; y: 3; width: parent.width - 6; height: 22
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: roja ? root.rojo : "#2f6b4e" }
            GradientStop { position: 1; color: roja ? "#6b1a1f" : "#5fa8a0" }
        }
        Text { anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
               text: parent.titulo; color: "#e4ffc4"; font.family: root.mono; font.pixelSize: 13; font.bold: true }
    }
    component Campo: Rectangle {
        property alias text: entrada.text
        property bool secreto: false
        signal aceptado()
        function enfocar() { entrada.forceActiveFocus(); }
        width: 260; height: 26; color: "#050806"
        Bisel { hundido: true }
        TextInput {
            id: entrada
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            verticalAlignment: TextInput.AlignVCenter
            color: root.texto; font.family: root.mono; font.pixelSize: 14
            selectionColor: root.verde; clip: true
            echoMode: parent.secreto ? TextInput.Password : TextInput.Normal
            onAccepted: parent.aceptado()
        }
    }
    component Boton: Rectangle {
        property string texto
        property bool rojo: false
        signal pulsado()
        width: 92; height: 26
        color: zona.containsMouse ? Qt.rgba(0.42, 0.76, 0.59, 0.18) : "#0d1310"
        Bisel { hundido: zona.pressed }
        Text { anchors.centerIn: parent; text: parent.texto; color: parent.rojo ? "#d0776f" : root.texto; font.family: root.mono; font.pixelSize: 12 }
        MouseArea { id: zona; anchors.fill: parent; hoverEnabled: true; onClicked: parent.pulsado() }
    }

    function entrar() { root.denegado = false; sddm.login(usuario.text, clave.text, root.sesion); }

    Rectangle {
        id: ventana
        readonly property real centroX: (root.width - width) / 2
        x: centroX
        y: (root.height - height) / 2
        width: 400; height: 222
        color: "#0d1310"
        Bisel {}
        Barra { titulo: "INICIAR SESIÓN" }

        SequentialAnimation {
            id: temblor
            loops: 3
            NumberAnimation { target: ventana; property: "x"; to: ventana.centroX - 10; duration: 50 }
            NumberAnimation { target: ventana; property: "x"; to: ventana.centroX + 10; duration: 50 }
            onFinished: ventana.x = Qt.binding(() => ventana.centroX)
        }

        Grid {
            x: 18; y: 42
            columns: 2; rowSpacing: 10; columnSpacing: 12
            verticalItemAlignment: Grid.AlignVCenter

            Text { text: "Usuario"; color: root.tenue; font.family: root.mono; font.pixelSize: 13 }
            Campo {
                id: usuario
                text: userModel.lastUser
                onAceptado: clave.enfocar()
            }
            Text { text: "Contraseña"; color: root.tenue; font.family: root.mono; font.pixelSize: 13 }
            Campo {
                id: clave
                secreto: true
                onAceptado: root.entrar()
            }
            Text { text: "Sesión"; color: root.tenue; font.family: root.mono; font.pixelSize: 13 }
            Rectangle {
                width: 260; height: 26; color: "transparent"
                Repeater {
                    model: sessionModel
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: index === root.sesion
                        text: "◀ " + model.name + " ▶"
                        color: root.lima; font.family: root.mono; font.pixelSize: 13
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sesion = (root.sesion + 1) % Math.max(1, sessionModel.rowCount())
                }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 16; bottom: parent.bottom; bottomMargin: 16 }
            spacing: 8
            Boton { texto: "Reiniciar"; visible: sddm.canReboot; onPulsado: sddm.reboot() }
            Boton { texto: "Apagar"; rojo: true; visible: sddm.canPowerOff; onPulsado: sddm.powerOff() }
            Boton { texto: "Entrar"; onPulsado: root.entrar() }
        }
    }

    // ---------- 警告 ----------
    Rectangle {
        visible: root.denegado
        anchors { horizontalCenter: ventana.horizontalCenter; top: ventana.bottom; topMargin: 14 }
        width: 300; height: 74
        color: "#0d1310"
        Bisel {}
        Barra { titulo: "警告"; roja: true }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
            text: "ACCESO DENEGADO"; color: root.rojo; font.family: root.mono; font.pixelSize: 16; font.bold: true
        }
    }

    Component.onCompleted: clave.enfocar()
}
