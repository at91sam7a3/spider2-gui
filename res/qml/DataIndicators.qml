import QtQuick
import QtQuick.Layouts

/**
 * @brief Data reception indicator component
 * Shows the status of lidar, gyro, and sensor data reception
 * Green = data received within last 1 second
 * Red = no data received (or timed out)
 */
Rectangle {
    id: dataIndicators
    color: "black"
    opacity: 0.7
    radius: 8
    border.color: "white"
    border.width: 1
    
    required property var telemetryData
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 15
        
        // Title
        Text {
            text: "Data Status:"
            color: "white"
            font.bold: true
            font.pixelSize: 13
            Layout.alignment: Qt.AlignVCenter
        }
        
        // Lidar indicator
        ColumnLayout {
            spacing: 4
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                id: lidarIndicator
                width: 20
                height: 20
                radius: 10
                color: (telemetryData && telemetryData["lidar_active"]) ? "#00ff00" : "#ff0000"
                border.color: "white"
                border.width: 1
                Layout.alignment: Qt.AlignHCenter
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
            
            Text {
                text: "LIDAR"
                color: "white"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        // Gyro indicator
        ColumnLayout {
            spacing: 4
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                id: gyroIndicator
                width: 20
                height: 20
                radius: 10
                color: (telemetryData && telemetryData["gyro_active"]) ? "#00ff00" : "#ff0000"
                border.color: "white"
                border.width: 1
                Layout.alignment: Qt.AlignHCenter
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
            
            Text {
                text: "GYRO"
                color: "white"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        // Telemetry/Sensor indicator
        ColumnLayout {
            spacing: 4
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                id: sensorIndicator
                width: 20
                height: 20
                radius: 10
                color: (telemetryData && telemetryData["telemetry_active"]) ? "#00ff00" : "#ff0000"
                border.color: "white"
                border.width: 1
                Layout.alignment: Qt.AlignHCenter
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
            
            Text {
                text: "SENSOR"
                color: "white"
                font.pixelSize: 10
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
