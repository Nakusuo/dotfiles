#!/usr/bin/env python3
"""Aplica una acción a una ventana de KWin desde el dock.
Uso: accion.py <accion> {uuid} [id-escritorio]
Carga un script de KWin de un solo uso (KWin no expone estas acciones por DBus)."""
import json, os, sys, tempfile, warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
from gi.repository import Gio, GLib

# `w` es la ventana; `extra` el argumento opcional (id del escritorio)
ACCIONES = {
    'minimizar': 'w.minimized = true;',
    'cerrar': 'w.closeWindow();',
    'encima': 'w.keepAbove = !w.keepAbove;',
    'completa': 'w.fullScreen = !w.fullScreen;',
    # Estas trabajan sobre la ventana activa, así que primero se activa
    'maximizar': 'workspace.activeWindow = w; workspace.slotWindowMaximize();',
    'mover': 'workspace.activeWindow = w; workspace.slotWindowMove();',
    'redimensionar': 'workspace.activeWindow = w; workspace.slotWindowResize();',
    'escritorio': 'const d = workspace.desktops.find(d => d.id === extra); if (d) w.desktops = [d];',
    'todos': 'w.onAllDesktops = !w.onAllDesktops;',
}
if len(sys.argv) < 3 or sys.argv[1] not in ACCIONES or not sys.argv[2].startswith('{'):
    sys.exit(f'uso: {sys.argv[0]} {"|".join(ACCIONES)} {{uuid}} [id-escritorio]')
accion, uuid = sys.argv[1], sys.argv[2]
extra = sys.argv[3] if len(sys.argv) > 3 else ''

js = f"""const extra = {json.dumps(extra)};
for (const w of workspace.windowList()) {{
    if (w.internalId.toString() === {json.dumps(uuid)}) {{ {ACCIONES[accion]} }}
}}"""
nombre = 'verdetech-dock-accion'
bus = Gio.bus_get_sync(Gio.BusType.SESSION)

def kwin(ruta, interfaz, metodo, args=None, tipo=None):
    return bus.call_sync('org.kde.KWin', ruta, interfaz, metodo, args,
                         GLib.VariantType(tipo) if tipo else None, 0, -1, None)

with tempfile.NamedTemporaryFile('w', suffix='.js', delete=False) as f:
    f.write(js)
try:
    kwin('/Scripting', 'org.kde.kwin.Scripting', 'unloadScript', GLib.Variant('(s)', (nombre,)))
    n = kwin('/Scripting', 'org.kde.kwin.Scripting', 'loadScript',
             GLib.Variant('(ss)', (f.name, nombre)), '(i)').unpack()[0]
    kwin(f'/Scripting/Script{n}', 'org.kde.kwin.Script', 'run')
    kwin('/Scripting', 'org.kde.kwin.Scripting', 'unloadScript', GLib.Variant('(s)', (nombre,)))
finally:
    os.unlink(f.name)
