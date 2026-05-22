import QtQuick

Rectangle {
    id: lidarDisplay
    width: 300
    height: 300
    color: "black"
    border.color: "white"
    border.width: 2
    radius: 8
    opacity: 0.9

    // Bind to LidarController (provides pointsXY + pointCount)
    property var controller: null
    property real maxDistance: 5.0

    Connections {
        target: controller
        function onPointsXYChanged() { lidarCanvas.requestPaint() }
    }

    Canvas {
        id: lidarCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Threaded   // paint off the GUI thread

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx    = width  / 2
            var cy    = height / 2
            var scale = Math.min(width, height) / (2.0 * lidarDisplay.maxDistance)

            // ── grid ─────────────────────────────────────────────────────────
            ctx.strokeStyle = "rgba(100,100,100,0.35)"
            ctx.lineWidth   = 1
            var rings = Math.ceil(lidarDisplay.maxDistance)
            for (var r = 1; r <= rings; r++) {
                ctx.beginPath()
                ctx.arc(cx, cy, r * scale, 0, 2 * Math.PI)
                ctx.stroke()
            }
            ctx.beginPath()
            ctx.moveTo(cx, 0);      ctx.lineTo(cx, height)
            ctx.moveTo(0,  cy);     ctx.lineTo(width, cy)
            ctx.stroke()

            // ── lidar points ──────────────────────────────────────────────────
            var pts = controller ? controller.pointsXY : []
            ctx.fillStyle = "#ff4444"
            var len = pts.length
            for (var i = 0; i < len; i += 2) {
                var px = cx + pts[i]     * scale
                var py = cy - pts[i + 1] * scale   // flip Y so forward = up
                ctx.fillRect(px - 2, py - 2, 4, 4)
            }

            // ── robot centre ──────────────────────────────────────────────────
            ctx.fillStyle = "#00ff00"
            ctx.beginPath()
            ctx.arc(cx, cy, 5, 0, 2 * Math.PI)
            ctx.fill()
        }
    }

    // Point counter
    Text {
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.margins: 5
        color:           "white"
        font.pixelSize:  10
        text:  controller ? ("Lidar: " + controller.pointCount + " pts") : "Lidar: –"
    }

    // Scale label
    Text {
        anchors.bottom:  parent.bottom
        anchors.right:   parent.right
        anchors.margins: 5
        color:           "white"
        font.pixelSize:  8
        text:  "Max: " + lidarDisplay.maxDistance.toFixed(1) + " m"
    }
}
