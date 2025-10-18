import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: telemetryDisplay
    color: "black"
    opacity: 0.7
    radius: 8
    border.color: "white"
    border.width: 1
    
    property var telemetryData: ({})
    property var robotState: ({})
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: 10
        clip: true
        
        ColumnLayout {
            width: telemetryDisplay.width - 20
            spacing: 8
            
            // Robot State Section
            Text {
                text: "Robot State"
                font.pixelSize: 16
                font.bold: true
                color: "white"
                Layout.fillWidth: true
            }
            
            Repeater {
                model: [
                    { label: "Forward Speed", value: robotState.forwardSpeed || 0 },
                    { label: "Strafe Speed", value: robotState.strafeSpeed || 0 },
                    { label: "Rotation Speed", value: robotState.rotationSpeed || 0 },
                    { label: "Height", value: robotState.height || 50 },
                    { label: "Walking Style", value: robotState.walkingStyle || 1 }
                ]
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Text {
                        text: modelData.label + ":"
                        color: "lightgray"
                        font.pixelSize: 12
                        Layout.preferredWidth: 120
                    }
                    
                    Text {
                        text: modelData.value.toFixed(2)
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "gray"
                Layout.topMargin: 5
                Layout.bottomMargin: 5
            }
            
            // Telemetry Data Section
            Text {
                text: "Telemetry Data"
                font.pixelSize: 16
                font.bold: true
                color: "white"
                Layout.fillWidth: true
            }
            
            Repeater {
                model: {
                    var items = [];
                    for (var key in telemetryData) {
                        if (key !== "lidar" && key !== "gyro") {
                            items.push({ key: key, value: telemetryData[key] });
                        }
                    }
                    return items;
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Text {
                        text: modelData.key + ":"
                        color: "lightgray"
                        font.pixelSize: 12
                        Layout.preferredWidth: 120
                    }
                    
                    Text {
                        text: modelData.value.toString()
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
            
            // LiDAR Data
            Repeater {
                model: telemetryData.lidar ? [
                    { label: "LiDAR Timestamp", value: telemetryData.lidar.timestamp },
                    { label: "LiDAR Angles", value: telemetryData.lidar.angle_count },
                    { label: "LiDAR Distances", value: telemetryData.lidar.distance_count }
                ] : []
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Text {
                        text: modelData.label + ":"
                        color: "lightblue"
                        font.pixelSize: 12
                        Layout.preferredWidth: 120
                    }
                    
                    Text {
                        text: modelData.value.toString()
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
            
            // Gyro Data
            Repeater {
                model: telemetryData.gyro ? [
                    { label: "Gyro X", value: telemetryData.gyro.x },
                    { label: "Gyro Y", value: telemetryData.gyro.y },
                    { label: "Gyro Timestamp", value: telemetryData.gyro.timestamp }
                ] : []
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Text {
                        text: modelData.label + ":"
                        color: "lightgreen"
                        font.pixelSize: 12
                        Layout.preferredWidth: 120
                    }
                    
                    Text {
                        text: modelData.value.toFixed(3)
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }
}
