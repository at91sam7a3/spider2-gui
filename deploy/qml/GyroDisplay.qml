import QtQuick
import QtQuick.Layouts

/**
 * @brief Gyroscope data visualization component
 * 
 * Displays gyroscope readings showing rotation data for X, Y, Z axes.
 * Shows current values and a simple graph of recent readings.
 */
Rectangle {
    id: gyroDisplay
    width: 250
    height: 200
    color: "black"
    border.color: "white"
    border.width: 2
    radius: 8
    opacity: 0.7
    
    property var controller
    property real maxValue: 10.0  // Maximum value for scaling (rad/s)
    
    // Current values display
    Column {
        id: valuesColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        spacing: 5
        
        Text {
            text: "Gyroscope Data"
            color: "white"
            font.pixelSize: 12
            font.bold: true
        }
        
        Text {
            text: "X: " + (controller ? controller.latestX.toFixed(3) : "0.000") + " rad/s"
            color: "red"
            font.pixelSize: 10
        }
        
        Text {
            text: "Y: " + (controller ? controller.latestY.toFixed(3) : "0.000") + " rad/s"
            color: "green"
            font.pixelSize: 10
        }
        
        Text {
            text: "Z: " + (controller ? controller.latestZ.toFixed(3) : "0.000") + " rad/s"
            color: "blue"
            font.pixelSize: 10
        }
    }
    
    // Simple bar chart visualization
    Row {
        id: barChart
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: 60
        spacing: 5
        
        // X-axis bar
        Rectangle {
            width: (parent.width - 20) / 3
            height: parent.height
            color: "transparent"
            border.color: "red"
            border.width: 1
            
            Rectangle {
                id: xBar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                height: Math.min(Math.abs(controller ? controller.latestX : 0) / gyroDisplay.maxValue * parent.height, parent.height)
                color: "red"
                opacity: 0.7
            }
            
            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "X"
                color: "red"
                font.pixelSize: 8
            }
        }
        
        // Y-axis bar
        Rectangle {
            width: (parent.width - 20) / 3
            height: parent.height
            color: "transparent"
            border.color: "green"
            border.width: 1
            
            Rectangle {
                id: yBar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                height: Math.min(Math.abs(controller ? controller.latestY : 0) / gyroDisplay.maxValue * parent.height, parent.height)
                color: "green"
                opacity: 0.7
            }
            
            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Y"
                color: "green"
                font.pixelSize: 8
            }
        }
        
        // Z-axis bar
        Rectangle {
            width: (parent.width - 20) / 3
            height: parent.height
            color: "transparent"
            border.color: "blue"
            border.width: 1
            
            Rectangle {
                id: zBar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 4
                height: Math.min(Math.abs(controller ? controller.latestZ : 0) / gyroDisplay.maxValue * parent.height, parent.height)
                color: "blue"
                opacity: 0.7
            }
            
            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Z"
                color: "blue"
                font.pixelSize: 8
            }
        }
    }
    
    // Data count indicator
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 5
        color: "white"
        font.pixelSize: 8
        text: "Readings: " + (controller ? controller.readingCount : 0)
    }
    
    // Scale indicator
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 5
        color: "white"
        font.pixelSize: 8
        text: "Max: " + maxValue.toFixed(1) + " rad/s"
    }
}
