import QtQuick
import QtQuick.Layouts
import Spider2 1.0

Window {
    id: mainWindow
    width: 1024
    height: 768
    visible: true
    title: "Spider2 Robot Control"
    
    property alias robotController: robotController
    
    // Robot controller instance
    RobotController {
        id: robotController
    }
    
    // Connection dialog
    ConnectionDialog {
        id: connectionDialog
        visible: !robotController.connected
        
        onConnectClicked: function(ip) {
            robotController.serverIp = ip
            robotController.connectToRobot()
        }
        
        onCancelClicked: {
            Qt.quit()
        }
    }
    
    // Main content area
    Rectangle {
        anchors.fill: parent
        color: "black"
        
        // Video background
        Image {
            id: videoImage
            anchors.fill: parent
            source: "image://video/stub"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        
        // OSD Overlay - Telemetry Display
        TelemetryDisplay {
            id: telemetryDisplay
            width: 300
            height: Math.min(400, parent.height - 20)
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            
            telemetryData: robotController.telemetryData
            robotState: {
                return {
                    forwardSpeed: robotController.forwardSpeed,
                    strafeSpeed: robotController.strafeSpeed,
                    rotationSpeed: robotController.rotationSpeed,
                    height: robotController.height,
                    walkingStyle: robotController.walkingStyle
                }
            }
        }
        
        // Connection status indicator
        Rectangle {
            id: connectionStatus
            width: 200
            height: 40
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 10
            color: robotController.connected ? "green" : "red"
            opacity: 0.8
            radius: 5
            
            Text {
                anchors.centerIn: parent
                text: robotController.connected ? "CONNECTED" : "DISCONNECTED"
                color: "white"
                font.bold: true
                font.pixelSize: 14
            }
        }
        
        // On-screen controls
        Rectangle {
            id: onScreenControls
            width: 200
            height: 300
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 10
            color: "black"
            opacity: 0.7
            radius: 8
            border.color: "white"
            border.width: 1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                Text {
                    text: "On-Screen Controls"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                }
                
                // Movement controls
                GridLayout {
                    columns: 3
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5
                    
                    // Empty cell for top-left
                    Item { width: 50; height: 50 }
                    
                    Rectangle {
                        width: 50
                        height: 50
                        color: "lightblue"
                        border.color: "black"
                        border.width: 1
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            font.pixelSize: 20
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: robotController.forwardSpeed = 1.0
                            onPressAndHold: robotController.forwardSpeed = 1.0
                            onReleased: robotController.forwardSpeed = 0.0
                        }
                    }
                    
                    // Empty cell for top-right
                    Item { width: 50; height: 50 }
                    
                    Button {
                        text: "←"
                        width: 50
                        height: 50
                        onClicked: robotController.strafeSpeed = -1.0
                        onPressAndHold: robotController.strafeSpeed = -1.0
                        onReleased: robotController.strafeSpeed = 0.0
                    }
                    
                    Button {
                        text: "STOP"
                        width: 50
                        height: 50
                        onClicked: {
                            robotController.forwardSpeed = 0.0
                            robotController.strafeSpeed = 0.0
                            robotController.rotationSpeed = 0.0
                        }
                    }
                    
                    Button {
                        text: "→"
                        width: 50
                        height: 50
                        onClicked: robotController.strafeSpeed = 1.0
                        onPressAndHold: robotController.strafeSpeed = 1.0
                        onReleased: robotController.strafeSpeed = 0.0
                    }
                    
                    // Empty cell for bottom-left
                    Item { width: 50; height: 50 }
                    
                    Button {
                        text: "↓"
                        width: 50
                        height: 50
                        onClicked: robotController.forwardSpeed = -1.0
                        onPressAndHold: robotController.forwardSpeed = -1.0
                        onReleased: robotController.forwardSpeed = 0.0
                    }
                    
                    // Empty cell for bottom-right
                    Item { width: 50; height: 50 }
                }
                
                // Rotation controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    
                    Button {
                        text: "↶"
                        width: 50
                        height: 40
                        onClicked: robotController.rotationSpeed = -1.0
                        onPressAndHold: robotController.rotationSpeed = -1.0
                        onReleased: robotController.rotationSpeed = 0.0
                    }
                    
                    Button {
                        text: "↷"
                        width: 50
                        height: 40
                        onClicked: robotController.rotationSpeed = 1.0
                        onPressAndHold: robotController.rotationSpeed = 1.0
                        onReleased: robotController.rotationSpeed = 0.0
                    }
                }
                
                // Height controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    
                    Text {
                        text: "Height:"
                        color: "white"
                        font.pixelSize: 12
                    }
                    
                    Button {
                        text: "-"
                        width: 30
                        height: 30
                        onClicked: robotController.height = Math.max(0, robotController.height - 5)
                    }
                    
                    Text {
                        text: robotController.height.toFixed(0)
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Button {
                        text: "+"
                        width: 30
                        height: 30
                        onClicked: robotController.height = Math.min(100, robotController.height + 5)
                    }
                }
                
                // Walking style controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5
                    
                    Text {
                        text: "Style:"
                        color: "white"
                        font.pixelSize: 12
                    }
                    
                    Repeater {
                        model: [1, 2, 3]
                        
                        Button {
                            text: modelData.toString()
                            width: 30
                            height: 30
                            highlighted: robotController.walkingStyle === modelData
                            onClicked: robotController.walkingStyle = modelData
                        }
                    }
                }
            }
        }
        
        // Instructions overlay
        Rectangle {
            id: instructions
            width: 250
            height: 120
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 10
            color: "black"
            opacity: 0.7
            radius: 8
            border.color: "white"
            border.width: 1
            
            Text {
                anchors.fill: parent
                anchors.margins: 10
                text: "Keyboard Controls:\nWASD - Movement\nQ/E - Rotation\nR/F - Height\n1/2/3 - Walking Style"
                color: "white"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
    
    // Keyboard event handling
    focus: true
    Keys.onPressed: function(event) {
        switch(event.key) {
            case Qt.Key_W:
                robotController.forwardSpeed = 1.0
                break
            case Qt.Key_S:
                robotController.forwardSpeed = -1.0
                break
            case Qt.Key_A:
                robotController.strafeSpeed = -1.0
                break
            case Qt.Key_D:
                robotController.strafeSpeed = 1.0
                break
            case Qt.Key_Q:
                robotController.rotationSpeed = -1.0
                break
            case Qt.Key_E:
                robotController.rotationSpeed = 1.0
                break
            case Qt.Key_R:
                robotController.height = Math.min(100, robotController.height + 5)
                break
            case Qt.Key_F:
                robotController.height = Math.max(0, robotController.height - 5)
                break
            case Qt.Key_1:
                robotController.walkingStyle = 1
                break
            case Qt.Key_2:
                robotController.walkingStyle = 2
                break
            case Qt.Key_3:
                robotController.walkingStyle = 3
                break
        }
    }
    
    Keys.onReleased: function(event) {
        switch(event.key) {
            case Qt.Key_W:
            case Qt.Key_S:
                robotController.forwardSpeed = 0.0
                break
            case Qt.Key_A:
            case Qt.Key_D:
                robotController.strafeSpeed = 0.0
                break
            case Qt.Key_Q:
            case Qt.Key_E:
                robotController.rotationSpeed = 0.0
                break
        }
    }
}
