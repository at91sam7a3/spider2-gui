import QtQuick
import QtQuick.Layouts
import Spider2 1.0

Window {
    id: mainWindow
    width: 800
    height: 600
    visible: true
    title: "Spider2 Robot Control"
    
    property alias robotController: robotController
    
    // Robot controller instance
    RobotController {
        id: robotController
    }
    
    Rectangle {
        anchors.fill: parent
        color: "black"
        focus: true
        
        // Video background
        Image {
            id: videoImage
            anchors.fill: parent
            source: "image://video/stub"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        
        // Simple connection dialog
        Rectangle {
            id: connectionDialog
            width: 350
            height: 200
            anchors.centerIn: parent
            color: "lightgray"
            border.color: "black"
            border.width: 2
            radius: 10
            visible: !robotController.connected
            
            property string robotIp: "192.168.1.100"
            
            Column {
                anchors.centerIn: parent
                spacing: 15
                
                Text {
                    text: "Connect to Spider2 Robot"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "Enter Robot IP Address:"
                    font.pixelSize: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Rectangle {
                    width: 200
                    height: 35
                    color: "white"
                    border.color: "black"
                    border.width: 1
                    radius: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    TextInput {
                        id: ipInput
                        anchors.fill: parent
                        anchors.margins: 8
                        text: connectionDialog.robotIp
                        font.pixelSize: 14
                        color: "black"
                        selectByMouse: true
                        cursorVisible: true
                        
                        onTextChanged: {
                            connectionDialog.robotIp = text
                        }
                        
                        Keys.onReturnPressed: {
                            connectButton.clicked()
                        }
                    }
                }
                
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 15
                    
                    Rectangle {
                        id: connectButton
                        width: 80
                        height: 30
                        color: "lightgreen"
                        border.color: "black"
                        border.width: 1
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: "black"
                            font.pixelSize: 12
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                robotController.serverIp = connectionDialog.robotIp
                                robotController.connectToRobot()
                            }
                        }
                    }
                    
                    Rectangle {
                        width: 80
                        height: 30
                        color: "lightcoral"
                        border.color: "black"
                        border.width: 1
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "black"
                            font.pixelSize: 12
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Qt.quit()
                            }
                        }
                    }
                }
            }
        }
        
        // Connection status
        Rectangle {
            width: 150
            height: 30
            anchors.verticalCenter: parent.verticalCenter
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
                font.pixelSize: 12
            }
        }
        
        // Simple telemetry display
        Rectangle {
            width: 200
            height: 100
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            color: "black"
            opacity: 0.7
            radius: 8
            border.color: "white"
            border.width: 1
            
            Column {
                anchors.centerIn: parent
                spacing: 5
                
                Text {
                    text: "Forward: " + robotController.forwardSpeed.toFixed(2)
                    color: "white"
                    font.pixelSize: 12
                }
                
                Text {
                    text: "Strafe: " + robotController.strafeSpeed.toFixed(2)
                    color: "white"
                    font.pixelSize: 12
                }
                
                Text {
                    text: "Rotation: " + robotController.rotationSpeed.toFixed(2)
                    color: "white"
                    font.pixelSize: 12
                }
            }
        }
        
        // Lidar display
        LidarDisplay {
            id: lidarDisplay
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 10
            model: robotController.lidarController ? robotController.lidarController.model : null
        }
        
        // Gyro display
        GyroDisplay {
            id: gyroDisplay
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            controller: robotController.gyroController
        }
        
        // Help message with hotkeys
        Rectangle {
            width: 400
            height: 100
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 10
            color: "black"
            opacity: 0.7
            radius: 8
            border.color: "white"
            border.width: 1
            
            Column {
                anchors.centerIn: parent
                spacing: 5
                
                Text {
                    text: "Movement Controls:"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "W/S - Forward/Backward  |  A/D - Strafe Left/Right  |  Q/E - Rotate Left/Right"
                    color: "white"
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "1/2/3 - Walking Style  |  +/- - Height Up/Down"
                    color: "white"
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        
        // Simple controls
        Rectangle {
            width: 200
            height: 200
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 10
            color: "black"
            opacity: 0.7
            radius: 8
            border.color: "white"
            border.width: 1
            
            Grid {
                anchors.centerIn: parent
                columns: 3
                spacing: 5
                
                // Empty cells for layout
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
                        onReleased: robotController.forwardSpeed = 0.0
                    }
                }
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
                        text: "←"
                        font.pixelSize: 20
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.strafeSpeed = -1.0
                        onReleased: robotController.strafeSpeed = 0.0
                    }
                }
                
                Rectangle {
                    width: 50
                    height: 50
                    color: "red"
                    border.color: "black"
                    border.width: 1
                    radius: 5
                    
                    Text {
                        anchors.centerIn: parent
                        text: "STOP"
                        font.pixelSize: 8
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            robotController.forwardSpeed = 0.0
                            robotController.strafeSpeed = 0.0
                            robotController.rotationSpeed = 0.0
                        }
                    }
                }
                
                Rectangle {
                    width: 50
                    height: 50
                    color: "lightblue"
                    border.color: "black"
                    border.width: 1
                    radius: 5
                    
                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        font.pixelSize: 20
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.strafeSpeed = 1.0
                        onReleased: robotController.strafeSpeed = 0.0
                    }
                }
                
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
                        text: "↓"
                        font.pixelSize: 20
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.forwardSpeed = -1.0
                        onReleased: robotController.forwardSpeed = 0.0
                    }
                }
                Item { width: 50; height: 50 }
            }
        }
        // Keyboard event handling
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
                case Qt.Key_1:
                    robotController.walkingStyle = 1
                    break
                case Qt.Key_2:
                    robotController.walkingStyle = 2
                    break
                case Qt.Key_3:
                    robotController.walkingStyle = 3
                    break
                case Qt.Key_Plus:
                case Qt.Key_Equal:
                    robotController.height = Math.min(robotController.height + 5, 100)
                    break
                case Qt.Key_Minus:
                    robotController.height = Math.max(robotController.height - 5, 0)
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
}
