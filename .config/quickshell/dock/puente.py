#!/usr/bin/env python3
"""Puente entre KWin y el dock de Quickshell.
Carga ventanas.js en KWin, recibe sus avisos por DBus y los imprime (una línea JSON por aviso)."""
import ctypes, os, signal, sys, warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
from gi.repository import Gio, GLib

NOMBRE = 'org.verdetech.Dock'
SCRIPT = 'verdetech-dock'
RUTA_JS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ventanas.js')
XML = f'''<node><interface name="{NOMBRE}">
  <method name="Update"><arg type="s" name="datos" direction="in"/></method>
</interface></node>'''

# Morir junto con el dock (si no, quedan puentes viejos peleando por el nombre)
ctypes.CDLL('libc.so.6').prctl(1, signal.SIGTERM)   # PR_SET_PDEATHSIG
if os.getppid() == 1:
    sys.exit(0)

bus = Gio.bus_get_sync(Gio.BusType.SESSION)
es_dueño = False

def kwin(ruta, interfaz, metodo, args=None, tipo=None):
    return bus.call_sync('org.kde.KWin', ruta, interfaz, metodo, args,
                         GLib.VariantType(tipo) if tipo else None, 0, -1, None)

def quitar_script():
    try:
        kwin('/Scripting', 'org.kde.kwin.Scripting', 'unloadScript', GLib.Variant('(s)', (SCRIPT,)))
    except GLib.Error:
        pass

def al_llamar(_con, _rem, _ruta, _iface, metodo, args, invocacion):
    if metodo == 'Update':
        print(args.unpack()[0], flush=True)
    invocacion.return_value(None)

def al_tener_nombre(*_):
    global es_dueño
    es_dueño = True
    quitar_script()
    n = kwin('/Scripting', 'org.kde.kwin.Scripting', 'loadScript',
             GLib.Variant('(ss)', (RUTA_JS, SCRIPT)), '(i)').unpack()[0]
    kwin(f'/Scripting/Script{n}', 'org.kde.kwin.Script', 'run')

def salir(*_):
    if es_dueño:   # solo quita el script de KWin si es el puente activo
        quitar_script()
    loop.quit()
    return False

def al_perder_nombre(*_):
    # Otro puente tomó el relevo: el script de KWin ahora es suyo, no tocarlo
    global es_dueño
    es_dueño = False
    loop.quit()

info = Gio.DBusNodeInfo.new_for_xml(XML)
bus.register_object('/', info.interfaces[0], al_llamar, None, None)
Gio.bus_own_name_on_connection(bus, NOMBRE, Gio.BusNameOwnerFlags.REPLACE | Gio.BusNameOwnerFlags.ALLOW_REPLACEMENT,
                               al_tener_nombre, al_perder_nombre)
loop = GLib.MainLoop()
for s in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, s, salir)
loop.run()
