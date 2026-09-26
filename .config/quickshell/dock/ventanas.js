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
            min: w.minimized
        });
        if (!w.minimized && w.output === pantalla && enEsteEscritorio(w)) {
            const f = w.frameGeometry;
            if (f.y + f.height > g.y + g.height - ALTO_DOCK) tapa = true;
        }
    }
    const datos = JSON.stringify({ ventanas: ventanas, tapa: tapa });
    if (datos === ultimo) return;
    ultimo = datos;
    callDBus("org.verdetech.Dock", "/", "org.verdetech.Dock", "Update", datos);
}

function vigilar(w) {
    w.minimizedChanged.connect(enviar);
    w.frameGeometryChanged.connect(enviar);
    w.captionChanged.connect(enviar);
    w.desktopsChanged.connect(enviar);
}

workspace.windowList().forEach(vigilar);
workspace.windowAdded.connect(w => { vigilar(w); enviar(); });
workspace.windowRemoved.connect(enviar);
workspace.windowActivated.connect(enviar);
workspace.currentDesktopChanged.connect(enviar);
enviar();
