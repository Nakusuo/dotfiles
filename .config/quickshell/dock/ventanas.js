// Script de KWin: avisa al dock (vía DBus) qué ventanas hay, cuál está activa
// y si alguna tapa la parte de abajo de la pantalla (para esconder el dock).
const ALTO_DOCK = 70;
let ultimo = "";

function enEsteEscritorio(w) {
    return w.onAllDesktops || w.desktops.some(d => d.id === workspace.currentDesktop.id);
}

function enviar() {
    const pantalla = workspace.activeScreen;
    const g = workspace.clientArea(KWin.FullScreenArea, pantalla, workspace.currentDesktop);
    const ventanas = [];
    let tapa = false;
    for (const w of workspace.windowList()) {
        if (!w.normalWindow || w.skipTaskbar) continue;
        ventanas.push({
            id: w.internalId.toString(),
            app: w.desktopFileName || "",
            cls: w.resourceClass || "",
            titulo: w.caption,
            activa: w === workspace.activeWindow,
            min: w.minimized,
            encima: w.keepAbove,
            completa: w.fullScreen,
            escritorios: w.onAllDesktops ? [] : w.desktops.map(d => d.id),
            aqui: enEsteEscritorio(w)     // el dock solo usa las ventanas del escritorio actual
        });
        if (!w.minimized && w.output === pantalla && enEsteEscritorio(w)) {
            const f = w.frameGeometry;
            if (f.y + f.height > g.y + g.height - ALTO_DOCK) tapa = true;
        }
    }
    const escritorios = workspace.desktops.map(d => ({ id: d.id, nombre: d.name, actual: d === workspace.currentDesktop }));
    const datos = JSON.stringify({ ventanas: ventanas, tapa: tapa, escritorios: escritorios });
    if (datos === ultimo) return;
    ultimo = datos;
    callDBus("org.verdetech.Dock", "/", "org.verdetech.Dock", "Update", datos);
}

function vigilar(w) {
    w.minimizedChanged.connect(enviar);
    w.frameGeometryChanged.connect(enviar);
    w.captionChanged.connect(enviar);
    w.desktopsChanged.connect(enviar);
    w.keepAboveChanged.connect(enviar);
    w.fullScreenChanged.connect(enviar);
}

workspace.windowList().forEach(vigilar);
workspace.windowAdded.connect(w => { vigilar(w); enviar(); });
workspace.windowRemoved.connect(enviar);
workspace.windowActivated.connect(enviar);
workspace.currentDesktopChanged.connect(enviar);
enviar();
