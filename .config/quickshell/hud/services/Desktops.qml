pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Escritorios virtuales de KWin via D-Bus
Singleton {
    id: root
    property int count: 5
    property int current: 1

    function go(n) {
        if (n < 1 || n > count) return;
        root.current = n; // respuesta inmediata en la UI
        Quickshell.execDetached(["qdbus6", "org.kde.KWin", "/KWin", "org.kde.KWin.setCurrentDesktop", String(n)]);
    }
    function next() { go(current >= count ? 1 : current + 1); }
    function prev() { go(current <= 1 ? count : current - 1); }

    Process {
        id: query
        command: ["sh", "-c", "echo $(qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count) $(qdbus6 org.kde.KWin /KWin org.kde.KWin.currentDesktop)"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(/\s+/);
                if (p.length === 2) {
                    root.count = parseInt(p[0]) || root.count;
                    root.current = parseInt(p[1]) || root.current;
                }
            }
        }
    }
    function refresh() { if (!query.running) query.running = true; }

    Timer { id: debounce; interval: 40; onTriggered: root.refresh() }

    Process {
        running: true
        command: ["dbus-monitor", "--session", "type='signal',interface='org.kde.KWin.VirtualDesktopManager'"]
        stdout: SplitParser { onRead: data => { if (data.indexOf("member=") !== -1) debounce.restart(); } }
    }

    Component.onCompleted: refresh()
}
