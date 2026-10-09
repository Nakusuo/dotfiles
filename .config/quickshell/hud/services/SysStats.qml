pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root
    property real cpu: 0      // 0..1
    property real ram: 0      // 0..1
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    readonly property real battery: {
        const p = UPower.displayDevice ? UPower.displayDevice.percentage : 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: !UPower.onBattery
    property string uptime: ""

    // Solo mide mientras el HUD está abierto (lo activa StatsPanel)
    property bool active: false
    onActiveChanged: _prev = null

    property var _prev: null

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: mem; path: "/proc/meminfo" }
    FileView { id: up; path: "/proc/uptime" }

    Timer {
        interval: 1500; running: root.active; repeat: true; triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload(); up.reload();
            const l = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            if (l.length > 4) {
                const idle = l[3] + (l[4] || 0);
                const total = l.reduce((a, b) => a + b, 0);
                if (root._prev) {
                    const dt = total - root._prev.total, di = idle - root._prev.idle;
                    if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
                }
                root._prev = { total: total, idle: idle };
            }
            const m = {};
            mem.text().split("\n").forEach(line => {
                const p = line.split(/:\s+/);
                if (p.length === 2) m[p[0]] = parseInt(p[1]);
            });
            if (m.MemTotal) {
                root.ramTotalGb = m.MemTotal / 1048576;
                root.ramUsedGb = (m.MemTotal - m.MemAvailable) / 1048576;
                root.ram = 1 - m.MemAvailable / m.MemTotal;
            }
            const s = Math.floor(parseFloat(up.text()));
            if (!isNaN(s)) {
                const h = Math.floor(s / 3600), mi = Math.floor((s % 3600) / 60);
                root.uptime = h + "H " + (mi < 10 ? "0" : "") + mi + "M";
            }
        }
    }
}
