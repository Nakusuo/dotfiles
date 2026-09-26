import QtQuick
import QtQuick.Shapes
import qs

Shape {
    id: root
    property color fill: "transparent"
    property color stroke: Theme.accent
    property real strokeWidth: 1.5
    preferredRendererType: Shape.CurveRenderer
    readonly property real r: Math.min(width, height) / 2 - strokeWidth
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    function pt(i) { const a = Math.PI / 180 * (60 * i - 90); return Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)); }
    ShapePath {
        fillColor: root.fill; strokeColor: root.stroke; strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin
        PathPolyline { path: [root.pt(0), root.pt(1), root.pt(2), root.pt(3), root.pt(4), root.pt(5), root.pt(0)] }
    }
}
