import QtQuick
import QtQuick.Layouts

/**
 * @brief Lidar data visualization component
 * 
 * Displays lidar readings as a square with:
 * - Green dot in the center (robot position)
 * - Red dots around the center representing obstacles
 * - Each dot is a rectangle with size 4x4 and radius 2
 */
Rectangle {
    id: lidarDisplay
    width: 300
    height: 300
    color: "black"
    border.color: "white"
    border.width: 2
    radius: 8
    opacity: 0.5
    
    property alias model: lidarRepeater.model
    property real maxDistance: 5.0  // Maximum distance to display (meters)
    property real scale: Math.min(width, height) / (2 * maxDistance)  // Scale factor for visualization
    
    // Center point (robot position)
    Rectangle {
        id: centerDot
        width: 4
        height: 4
        radius: 2
        color: "green"
        anchors.centerIn: parent
    }
    
    // Lidar data points
    Repeater {
        id: lidarRepeater
        model: lidarDisplay.model
        
        delegate: Rectangle {
            id: lidarPoint
            width: 4
            height: 4
            radius: 2
            color: "red"
            
            // Convert polar coordinates to screen coordinates
            x: parent.width / 2 + (model.x * lidarDisplay.scale) - width / 2
            y: parent.height / 2 - (model.y * lidarDisplay.scale) - height / 2  // Flip Y axis
            
            // Only show points within the display area
            visible: {
                var distance = Math.sqrt(model.x * model.x + model.y * model.y)
                return distance <= lidarDisplay.maxDistance && distance > 0
            }
        }
    }
    
    // Grid lines for reference
    Canvas {
        id: gridCanvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            // Set grid properties
            ctx.strokeStyle = "rgba(100, 100, 100, 0.3)"
            ctx.lineWidth = 1
            
            var centerX = width / 2
            var centerY = height / 2
            var gridSpacing = lidarDisplay.scale * 1.0  // 1 meter spacing
            
            // Draw concentric circles
            for (var i = 1; i <= lidarDisplay.maxDistance; i++) {
                var radius = i * gridSpacing
                ctx.beginPath()
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                ctx.stroke()
            }
            
            // Draw cross lines
            ctx.beginPath()
            ctx.moveTo(centerX, 0)
            ctx.lineTo(centerX, height)
            ctx.moveTo(0, centerY)
            ctx.lineTo(width, centerY)
            ctx.stroke()
        }
        
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
    
    // Info text
    Text {
        id: infoText
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 5
        color: "white"
        font.pixelSize: 10
        text: "Lidar: " + (lidarDisplay.model ? lidarDisplay.model.count : 0) + " points"
    }
    
    // Distance scale text
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 5
        color: "white"
        font.pixelSize: 8
        text: "Max: " + maxDistance.toFixed(1) + "m"
    }
}
