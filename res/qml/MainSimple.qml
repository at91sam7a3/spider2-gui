import QtQuick
import QtQuick.Layouts
import Spider2 1.0
import "."

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
        objectName: "robotController"
    }
    
    Rectangle {
        anchors.fill: parent
        color: "black"
        focus: true
        
        // Video background — source includes frame index so QML reloads on every new frame
        Image {
            id: videoImage
            anchors.fill: parent
            source: "image://video/frame?" + robotController.videoFrameIndex
            fillMode: Image.PreserveAspectFit
            smooth: true
            cache: false
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
        
        // Data stream health (green = received within 1s, red = stale)
        Row {
            id: streamHealthBar
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
            spacing: 10
            visible: robotController.connected

            DataStreamIndicator {
                label: "Lidar"
                active: robotController.lidarStreamActive
            }
            DataStreamIndicator {
                label: "Sensors"
                active: robotController.sensorsStreamActive
            }
            DataStreamIndicator {
                label: "Gyro"
                active: robotController.gyroStreamActive
            }
            DataStreamIndicator {
                label: "SLAM"
                active: robotController.slamStreamActive
            }
        }

        // Servo ON / OFF — left side, vertical center
        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            spacing: 8
            visible: robotController.connected

            // Servo ON
            Rectangle {
                width: 90
                height: 40
                radius: 6
                color: servoOnMA.pressed ? "#1a7a1a" : "#228b22"
                border.color: "#44ff44"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Servo ON"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: servoOnMA
                    anchors.fill: parent
                    onClicked: robotController.setServoTorque(true)
                }
            }

            // Servo OFF
            Rectangle {
                width: 90
                height: 40
                radius: 6
                color: servoOffMA.pressed ? "#7a1a1a" : "#8b2222"
                border.color: "#ff4444"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Servo OFF"
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: servoOffMA
                    anchors.fill: parent
                    onClicked: robotController.setServoTorque(false)
                }
            }
        }

        // Sensor data block — top right
        SensorDataDisplay {
            id: sensorDataDisplay
            width: 220
            height: 205
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            visible: robotController.connected
            telemetryData: robotController.telemetryData
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
        
        // SLAM pose display
        Rectangle {
            width: 200
            height: 80
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 115
            anchors.leftMargin: 10
            color: "black"
            opacity: 0.7
            radius: 8
            border.color: "white"
            border.width: 1
            visible: robotController.slamStreamActive
            
            Column {
                anchors.centerIn: parent
                spacing: 4
                
                Text {
                    text: "SLAM Position"
                    color: "#88ff88"
                    font.pixelSize: 11
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "X: " + robotController.slamController.posX.toFixed(0) + " mm"
                    color: "white"
                    font.pixelSize: 11
                }
                
                Text {
                    text: "Y: " + robotController.slamController.posY.toFixed(0) + " mm"
                    color: "white"
                    font.pixelSize: 11
                }
                
                Text {
                    text: "θ: " + robotController.slamController.posTheta.toFixed(1) + "°"
                    color: "white"
                    font.pixelSize: 11
                }
            }
        }
        
        // Lidar display
        LidarDisplay {
            id: lidarDisplay
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 10
            controller: robotController.lidarController ?? null
        }
        
        // Artificial horizon — centered over the video feed
        ArtificialHorizon {
            id: artificialHorizon
            anchors.centerIn: parent
            visible: robotController.connected
            roll:  robotController.gyroController.latestX
            pitch: robotController.gyroController.latestY
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
        
        // ── Joystick + rotation + height controls (bottom-right) ────────────
        Item {
            id: controlPanel
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 10

            // Layout constants
            readonly property int jsSize:     180   // joystick square side / slider length
            readonly property int slimW:       30   // thin-slider thickness
            readonly property int gap:          4   // gap between panels
            readonly property int knobR:       13   // knob radius
            readonly property real halfTravel: (jsSize - knobR * 2) / 2  // px from center to edge

            width:  jsSize + gap + slimW
            height: jsSize + gap + slimW

            // ── 1. XY Joystick (strafe / forward) ────────────────────────
            Rectangle {
                id: joystickPane
                x: 0; y: 0
                width:  controlPanel.jsSize
                height: controlPanel.jsSize
                color: "#1a1a1a"
                border.color: "#4a4a4a"
                border.width: 1
                radius: 6
                clip: true

                // Cross-hair guides
                Rectangle { anchors.centerIn: parent; width: parent.width; height: 1; color: "#2a2a2a" }
                Rectangle { anchors.centerIn: parent; width: 1; height: parent.height; color: "#2a2a2a" }

                // Corner label
                Text {
                    anchors { bottom: parent.bottom; right: parent.right; margins: 4 }
                    text: "MOVE"
                    color: "#505050"
                    font.pixelSize: 9
                }

                // Knob — position is a pure binding on the controller properties
                Rectangle {
                    id: jsKnob
                    width:  controlPanel.knobR * 2
                    height: controlPanel.knobR * 2
                    radius: controlPanel.knobR
                    // center offset = normalised value * halfTravel
                    x: joystickPane.width  / 2 - controlPanel.knobR
                       + (robotController.strafeSpeed  / 2.0) * controlPanel.halfTravel
                    y: joystickPane.height / 2 - controlPanel.knobR
                       - (robotController.forwardSpeed / 2.0) * controlPanel.halfTravel
                    color: (Math.abs(robotController.strafeSpeed)  < 0.01 &&
                            Math.abs(robotController.forwardSpeed) < 0.01) ? "#cc3333" : "#ddbb00"
                    layer.enabled: true
                    layer.effect: null
                }

                MouseArea {
                    id: joystickMA
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed:         function(mouse) { applyJoystick(mouse) }
                    onPositionChanged: function(mouse) {
                        if (joystickMA.pressedButtons & Qt.LeftButton)
                            applyJoystick(mouse)
                    }

                    function applyJoystick(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            robotController.strafeSpeed  = 0.0
                            robotController.forwardSpeed = 0.0
                            return
                        }
                        var cx = joystickPane.width  / 2
                        var cy = joystickPane.height / 2
                        var ht = controlPanel.halfTravel
                        robotController.strafeSpeed  = Math.max(-2.0, Math.min(2.0,
                            (mouse.x - cx) / ht * 2.0))
                        robotController.forwardSpeed = Math.max(-2.0, Math.min(2.0,
                            (cy - mouse.y) / ht * 2.0))
                    }
                }
            }

            // ── 2. Rotation slider (horizontal, below joystick) ───────────
            Rectangle {
                id: rotPane
                x: 0
                y: controlPanel.jsSize + controlPanel.gap
                width:  controlPanel.jsSize
                height: controlPanel.slimW
                color: "#1a1a1a"
                border.color: "#4a4a4a"
                border.width: 1
                radius: height / 2
                clip: true

                Rectangle { anchors.centerIn: parent; width: 1; height: parent.height * 0.6; color: "#2a2a2a" }

                Text {
                    anchors { bottom: parent.bottom; right: parent.right; margins: 4 }
                    text: "ROT"
                    color: "#505050"
                    font.pixelSize: 8
                }

                Rectangle {
                    id: rotKnob
                    width:  controlPanel.knobR * 2
                    height: controlPanel.knobR * 2
                    radius: controlPanel.knobR
                    x: rotPane.width / 2 - controlPanel.knobR
                       + robotController.rotationSpeed * controlPanel.halfTravel
                    y: rotPane.height / 2 - controlPanel.knobR
                    color: Math.abs(robotController.rotationSpeed) < 0.01 ? "#cc3333" : "#ddbb00"
                }

                MouseArea {
                    id: rotMA
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed:         function(mouse) { applyRot(mouse) }
                    onPositionChanged: function(mouse) {
                        if (rotMA.pressedButtons & Qt.LeftButton)
                            applyRot(mouse)
                    }

                    function applyRot(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            robotController.rotationSpeed = 0.0
                            return
                        }
                        var cx = rotPane.width / 2
                        robotController.rotationSpeed = Math.max(-1.0, Math.min(1.0,
                            (mouse.x - cx) / controlPanel.halfTravel))
                    }
                }
            }

            // ── 3. Height slider (vertical, right of joystick) ────────────
            Rectangle {
                id: heightPane
                x: controlPanel.jsSize + controlPanel.gap
                y: 0
                width:  controlPanel.slimW
                height: controlPanel.jsSize
                color: "#1a1a1a"
                border.color: "#4a4a4a"
                border.width: 1
                radius: width / 2
                clip: true

                Rectangle { anchors.centerIn: parent; width: parent.width * 0.6; height: 1; color: "#2a2a2a" }

                Text {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 4 }
                    text: "H"
                    color: "#505050"
                    font.pixelSize: 8
                }

                // normH: 0 = 40 mm (bottom), 1 = 150 mm (top), ~0.09 = 50 mm default
                // knob moves up as height increases (normH → 1 = top of slider)
                Rectangle {
                    id: heightKnob
                    width:  controlPanel.knobR * 2
                    height: controlPanel.knobR * 2
                    radius: controlPanel.knobR
                    property real normH: Math.max(0.0, Math.min(1.0,
                        (robotController.height - 40.0) / 110.0))
                    x: heightPane.width  / 2 - controlPanel.knobR
                    y: heightPane.height / 2 - controlPanel.knobR
                       - (normH - 0.5) * 2.0 * controlPanel.halfTravel
                    color: Math.abs(robotController.height - 50.0) < 2.0 ? "#cc3333" : "#ddbb00"
                }

                MouseArea {
                    id: heightMA
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed:         function(mouse) { applyHeight(mouse) }
                    onPositionChanged: function(mouse) {
                        if (heightMA.pressedButtons & Qt.LeftButton)
                            applyHeight(mouse)
                    }

                    function applyHeight(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            robotController.height = 50.0   // robot default
                            return
                        }
                        var cy = heightPane.height / 2
                        var nh = Math.max(0.0, Math.min(1.0,
                            0.5 + (cy - mouse.y) / (controlPanel.halfTravel * 2.0)))
                        robotController.height = 40.0 + nh * 110.0  // → 40..150 mm
                    }
                }
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
                    robotController.height = Math.min(robotController.height + 5.0, 150.0)
                    break
                case Qt.Key_Minus:
                    robotController.height = Math.max(robotController.height - 5.0, 40.0)
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
