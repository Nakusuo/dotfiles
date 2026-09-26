import QtQuick
import QtQuick.Shapes
import qs

// Arco vectorial reutilizable
Shape {
    id: root
    property real radius: width / 2 - strokeWidth
    property real strokeWidth: 2
    property color color: Theme.accent
    property real startAngle: -90
    property real sweep: 360
    property var dash: []
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeColor: root.color
        strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: root.dash.length ? ShapePath.FlatCap : ShapePath.RoundCap
        strokeStyle: root.dash.length ? ShapePath.DashLine : ShapePath.SolidLine
        dashPattern: root.dash.length ? root.dash : [1, 0]
        PathAngleArc {
            centerX: root.width / 2; centerY: root.height / 2
            radiusX: root.radius; radiusY: root.radius
            startAngle: root.startAngle; sweepAngle: root.sweep
        }
    }
}
