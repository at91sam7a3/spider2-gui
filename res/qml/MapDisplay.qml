import QtQuick

Rectangle {
    id: mapDisplay
    width: 300
    height: 300
    color: "black"
    border.color: "white"
    border.width: 2
    radius: 8
    opacity: 0.9
    clip: true

    property var controller: null
    property real mapPhysicalSize: (controller ? controller.mapSizeMeters : 20.0) || 20.0

    // Fullscreen mode (use with NAV button)
    property bool fullscreen: false
    onFullscreenChanged: {
        if (fullscreen) {
            mapDisplay.radius = 0
            mapDisplay.border.width = 0
            mapDisplay.opacity = 1.0
        } else {
            mapDisplay.radius = 8
            mapDisplay.border.width = 2
            mapDisplay.opacity = 0.9
        }
    }

    // Pan & zoom state
    property real panX: 0
    property real panY: 0
    property real zoom: 1.0
    property real zoomMin: 0.3
    property real zoomMax: 10.0

    // Force image re-fetch when becoming visible (e.g. NAV mode toggle)
    property int refreshToken: 0
    onVisibleChanged: { if (visible) refreshToken++ }

    // Drag tracking
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragPanX: 0
    property real dragPanY: 0
    property bool dragging: false

    // ── Emitted on right-click when map data exists ──
    signal navigateToPoint(real worldX_mm, real worldY_mm)

    function resetView() {
        panX = 0; panY = 0; zoom = 1.0
    }

    // Convert a mouse position (in our coordinates) to map world mm.
    // Returns [worldX_mm, worldY_mm] or null if no map data.
    function screenToWorld(mx, my) {
        if (!controller || !controller.hasData) return null
        var iw = mapImage.width, ih = mapImage.height
        if (iw <= 0 || ih <= 0) return null

        // Undo zoom/pan to get the coords in the mapImage's local space
        var lx = (mx - mapDisplay.panX - iw / 2) / mapDisplay.zoom + iw / 2
        var ly = (my - mapDisplay.panY - ih / 2) / mapDisplay.zoom + ih / 2

        // Convert image-local to world mm (accounting for PreserveAspectFit painting)
        var pw = mapImage.paintedWidth, ph = mapImage.paintedHeight
        var px = mapImage.paintedX, py = mapImage.paintedY
        if (pw <= 0 || ph <= 0) return null

        var worldX_mm = (lx - px) * mapPhysicalSize / pw * 1000.0
        var worldY_mm = (ly - py) * mapPhysicalSize / ph * 1000.0
        return [worldX_mm, worldY_mm]
    }

    // Convert world mm to screen pixel (for arrow positioning)
    function worldToScreen(worldX_mm, worldY_mm) {
        if (!controller || !controller.hasData) return null
        var iw = mapImage.width, ih = mapImage.height
        var pw = mapImage.paintedWidth, ph = mapImage.paintedHeight
        var px = mapImage.paintedX, py = mapImage.paintedY
        if (pw <= 0 || ph <= 0) return null

        // World mm → image-local pixels (origin at top-left)
        var lx = px + (worldX_mm / 1000.0) * pw / mapPhysicalSize
        var ly = py + (worldY_mm / 1000.0) * ph / mapPhysicalSize

        // Apply zoom/pan
        var sx = (lx - iw / 2) * mapDisplay.zoom + iw / 2 + mapDisplay.panX
        var sy = (ly - ih / 2) * mapDisplay.zoom + ih / 2 + mapDisplay.panY
        return [sx, sy]
    }

    // Pannable/zoomable view — map + robot share a single transform
    Item {
        id: mapView
        anchors.fill: parent

        transform: [
            Translate { x: mapDisplay.panX; y: mapDisplay.panY },
            Scale {
                origin.x: mapView.width  / 2
                origin.y: mapView.height / 2
                xScale: mapDisplay.zoom
                yScale: mapDisplay.zoom
            }
        ]

        Image {
            id: mapImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            cache: false
            source: controller ? "image://map/frame?idx=" + controller.mapFrameIndex + "&t=" + mapDisplay.refreshToken : ""
            antialiasing: false
            smooth: false
        }

        // Fallback text when no map data
        Text {
            anchors.centerIn: parent
            color: "#555"
            font.pixelSize: 14
            text: "SLAM: no data"
            visible: !(controller && controller.hasData)
            z: 5
        }

        // Robot circle — in image-local coords (transform inherited from mapView)
        Rectangle {
            id: robotCircle
            visible: controller && controller.hasData
            color: "transparent"
            border.color: "#00aaff"
            border.width: 3

            property real pw:  mapImage.paintedWidth  || 0
            property real ph:  mapImage.paintedHeight || 0
            property real ppx: (mapImage.width - pw) / 2 || 0
            property real ppy: (mapImage.height - ph) / 2 || 0

            property real robotR: {
                if (!controller || !controller.hasData || pw <= 0) return 6
                return Math.max(4, 0.3 * pw / controller.mapSizeMeters * 1.0)
            }

            width:  robotR * 2
            height: robotR * 2
            radius: robotR
            x: ppx + (controller.posX / 1000.0) * pw / mapPhysicalSize - robotR
            y: ppy + (controller.posY / 1000.0) * ph / mapPhysicalSize - robotR
        }

        // Direction arrow — in image-local coords
        Image {
            id: robotArrow
            visible: controller && controller.hasData
            source: "arrow.svg"
            sourceSize.width:  24
            sourceSize.height: 30
            smooth: true

            property real pw:  mapImage.paintedWidth  || 0
            property real ph:  mapImage.paintedHeight || 0
            property real ppx: (mapImage.width - pw) / 2 || 0
            property real ppy: (mapImage.height - ph) / 2 || 0

            x: ppx + (controller.posX / 1000.0) * pw / mapPhysicalSize - width  / 2
            y: ppy + (controller.posY / 1000.0) * ph / mapPhysicalSize - height / 2

            transform: Rotation {
                origin.x: robotArrow.width  / 2
                origin.y: robotArrow.height / 2
                angle: (controller ? 90 + controller.posTheta : 0)
            }
        }
    }

    // Mouse area for pan & zoom (left) and navigate (right)
    MouseArea {
        id: mapMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                var w = mapDisplay.screenToWorld(mouse.x, mouse.y)
                if (w) {
                    mapDisplay.navigateToPoint(w[0], w[1])
                }
                return
            }
            dragStartX = mouse.x
            dragStartY = mouse.y
            dragPanX = mapDisplay.panX
            dragPanY = mapDisplay.panY
            dragging = true
        }

        onPositionChanged: function(mouse) {
            if (dragging && (pressedButtons & Qt.LeftButton)) {
                mapDisplay.panX = dragPanX + (mouse.x - dragStartX)
                mapDisplay.panY = dragPanY + (mouse.y - dragStartY)
            }
        }

        onReleased: {
            dragging = false
        }

        onWheel: function(wheel) {
            var oldZoom = mapDisplay.zoom
            var zoomFactor = wheel.angleDelta.y > 0 ? 1.1 : 1.0 / 1.1
            var newZoom = Math.max(mapDisplay.zoomMin, Math.min(mapDisplay.zoomMax, oldZoom * zoomFactor))

            var mouseRatioX = wheel.x / mapDisplay.width
            var mouseRatioY = wheel.y / mapDisplay.height
            var worldX = (mouseRatioX - 0.5) * mapDisplay.width / oldZoom - mapDisplay.panX / oldZoom
            var worldY = (mouseRatioY - 0.5) * mapDisplay.height / oldZoom - mapDisplay.panY / oldZoom

            mapDisplay.zoom = newZoom
            mapDisplay.panX = -(worldX * newZoom - (mouseRatioX - 0.5) * mapDisplay.width)
            mapDisplay.panY = -(worldY * newZoom - (mouseRatioY - 0.5) * mapDisplay.height)
        }
    }

    // Title label
    Text {
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.margins: 5
        color:           "white"
        font.pixelSize:  10
        text: controller && controller.hasData
            ? ("Map: " + controller.mapSizePixels + "px / " + controller.mapSizeMeters.toFixed(1) + "m")
            : "SLAM Map: \u2014"
        z: 10
    }

    // Scale / zoom label
    Text {
        anchors.bottom:  parent.bottom
        anchors.right:   parent.right
        anchors.margins: 5
        color:           "white"
        font.pixelSize:  8
        text: controller && controller.hasData
            ? (controller.mapSizeMeters.toFixed(1) + " m  \u00D7" + mapDisplay.zoom.toFixed(1))
            : ""
        z: 10
    }
}
