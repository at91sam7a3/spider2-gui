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
    
    // Navigation mode toggle
    property bool navMode: false

    // Nav map pan/zoom state (inlined, no MapDisplay)
    property real navPanX: 0
    property real navPanY: 0
    property real navZoom: 1.0

    function setNavMode(mode) {
        navMode = mode
    }
    
    RobotController {
        id: robotController
        objectName: "robotController"
    }
    
    Rectangle {
        anchors.fill: parent
        color: "black"
        focus: true
        
        // ── Layer 1: Video background (hidden in nav mode) ──
        Image {
            id: videoImage
            anchors.fill: parent
            source: "image://video/frame?" + robotController.videoFrameIndex
            fillMode: Image.PreserveAspectFit
            smooth: true
            cache: false
            visible: !navMode
        }
        
        // ── Blob tracking overlay rectangle ──
        Item {
            id: blobRect
            anchors.fill: videoImage
            visible: robotController.hasBlob && !navMode

            // Assume square blob; compute source-side pixel size and scale to display
            readonly property real fw: Math.max(robotController.blobFrameWidth,  1)
            readonly property real fh: Math.max(robotController.blobFrameHeight, 1)
            readonly property real blobSideSrc: Math.sqrt(robotController.blobSize * fw * fh)
            readonly property real displayScale: Math.min(width / fw, height / fh)
            readonly property real pw: fw * displayScale
            readonly property real ph: fh * displayScale
            readonly property real px: (width  - pw) / 2
            readonly property real py: (height - ph) / 2

            Rectangle {
                color: "transparent"
                border.color: "#00ff00"
                border.width: 3

                readonly property real side: blobRect.blobSideSrc * blobRect.displayScale
                readonly property real cx: blobRect.px + (robotController.blobX + 1.0) / 2.0 * blobRect.pw
                readonly property real cy: blobRect.py + (robotController.blobY + 1.0) / 2.0 * blobRect.ph

                x: cx - side / 2
                y: cy - side / 2
                width:  side
                height: side
            }
        }

        // ── Layer 2: Full-window map (shown in nav mode) ──
        // ── Connection dialog ──
        Rectangle {
            id: connectionDialog
            width: 360
            height: 320
            anchors.centerIn: parent
            color: "lightgray"
            border.color: "black"
            border.width: 2
            radius: 10
            visible: !robotController.connected
            clip: true
            
            property string robotIp: "spider.local"
            
            Column {
                anchors.centerIn: parent
                spacing: 8
                width: parent.width - 30
                
                Text {
                    text: "Connect to Spider2 Robot"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "Enter Robot IP Address or select from recent:"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#444"
                }
                
                Rectangle {
                    width: 220
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
                
                Rectangle {
                    width: 220
                    height: childrenRect.height + 8
                    color: "#f0f0f0"
                    border.color: "#aaa"
                    border.width: 1
                    radius: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: robotController.recentServerIps.length > 0
                    
                    Column {
                        width: parent.width - 8
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        
                        Repeater {
                            model: robotController.recentServerIps
                            
                            Rectangle {
                                width: parent.width
                                height: 22
                                color: listMA.containsMouse ? "#d0e0f0" : "transparent"
                                radius: 3
                                
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    font.pixelSize: 12
                                    color: listMA.containsMouse ? "#000080" : "#333"
                                }
                                
                                MouseArea {
                                    id: listMA
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        connectionDialog.robotIp = modelData
                                        ipInput.text = modelData
                                    }
                                }
                            }
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
        
        // ── Overlay controls (hidden in nav mode) ──
        Item {
            anchors.fill: parent
            visible: robotController.connected && !navMode

            // Data stream health — top center
            Row {
                id: streamHealthBar
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10
                spacing: 10

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

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "white"
                    opacity: 0.2
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Trajectory: LinearSine button
                Rectangle {
                    id: trajLinButton
                    width: 45
                    height: 26
                    radius: 5
                    color: robotController.trajectoryType === 0 ? "#3498db" : "#444444"
                    border.color: robotController.trajectoryType === 0 ? "#5dade2" : "white"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "LIN"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.trajectoryType = 0
                    }
                }

                // Trajectory: Cycloid button
                Rectangle {
                    id: trajCycButton
                    width: 45
                    height: 26
                    radius: 5
                    color: robotController.trajectoryType === 1 ? "#9b59b6" : "#444444"
                    border.color: robotController.trajectoryType === 1 ? "#d7bde2" : "white"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "CYC"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.trajectoryType = 1
                    }
                }
            }

            // Left column: Servo + NAV + Walking style + Robot state
            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                spacing: 8

                // Servo ON
                Rectangle {
                    width: 90; height: 40; radius: 6
                    color: servoOnMA.pressed ? "#1a7a1a" : "#228b22"
                    border.color: "#44ff44"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Servo ON"; color: "white"
                        font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        id: servoOnMA
                        anchors.fill: parent
                        onClicked: robotController.setServoTorque(true)
                    }
                }

                // Servo OFF
                Rectangle {
                    width: 90; height: 40; radius: 6
                    color: servoOffMA.pressed ? "#7a1a1a" : "#8b2222"
                    border.color: "#ff4444"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Servo OFF"; color: "white"
                        font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        id: servoOffMA
                        anchors.fill: parent
                        onClicked: robotController.setServoTorque(false)
                    }
                }

                // NAV toggle button
                Rectangle {
                    width: 90; height: 40; radius: 6
                    color: navMode ? "#cc8800" : "#886622"
                    border.color: navMode ? "#ffcc00" : "#aa8844"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: navMode ? "MAP" : "NAV"
                        color: "white"; font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mainWindow.setNavMode(!navMode)
                    }
                }

                // Separator
                Rectangle { width: 90; height: 1; color: "#444"; }

                // ── Object Tracking toggle ──
                Rectangle {
                    width: 90; height: 40; radius: 6
                    color: robotController.objectTracking ? "#226644" : "#222"
                    border.color: robotController.objectTracking ? "#44ff88" : "#444"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Track"
                        color: robotController.objectTracking ? "#44ff88" : "#888"
                        font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.setObjectTracking(!robotController.objectTracking)
                    }
                }

                // Separator
                Rectangle { width: 90; height: 1; color: "#444"; }

                // ── Robot state radio group ──
                Text { text: "STATE"; color: "#aaa"; font.pixelSize: 9; font.bold: true }

                Rectangle {
                    width: 90; height: 26; radius: 4
                    color: robotController.telemetryData["robot_state"] !== "move_to_point" ? "#336633" : "#222"
                    border.color: robotController.telemetryData["robot_state"] !== "move_to_point" ? "#44ff44" : "#444"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Manual"
                        color: robotController.telemetryData["robot_state"] !== "move_to_point" ? "#44ff44" : "#888"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.sendStateChange("manual_control")
                    }
                }

                Rectangle {
                    width: 90; height: 26; radius: 4
                    color: robotController.telemetryData["robot_state"] === "move_to_point" ? "#336633" : "#222"
                    border.color: robotController.telemetryData["robot_state"] === "move_to_point" ? "#44ff44" : "#444"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Follow Pt"
                        color: robotController.telemetryData["robot_state"] === "move_to_point" ? "#44ff44" : "#888"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: robotController.sendStateChange("move_to_point")
                    }
                }
            }

            // Sensor data block — top right
            SensorDataDisplay {
                id: sensorDataDisplay
                width: 220; height: 205
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: 10
                telemetryData: robotController.telemetryData
            }

            // Connection status
            Rectangle {
                width: 150; height: 30
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right; anchors.margins: 10
                color: robotController.connected ? "green" : "red"
                opacity: 0.8; radius: 5
                Text {
                    anchors.centerIn: parent
                    text: robotController.connected ? "CONNECTED" : "DISCONNECTED"
                    color: "white"; font.bold: true; font.pixelSize: 12
                }
            }

            // Simple telemetry — top left
            Rectangle {
                width: 220; height: 140
                anchors.top: parent.top; anchors.left: parent.left
                anchors.margins: 10
                color: "black"; opacity: 0.7; radius: 8
                border.color: "white"; border.width: 1
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Text { text: "Forward: " + robotController.forwardSpeed.toFixed(2); color: "white"; font.pixelSize: 11 }
                    Text { text: "Strafe: " + robotController.strafeSpeed.toFixed(2); color: "white"; font.pixelSize: 11 }
                    Text { text: "Rotation: " + robotController.rotationSpeed.toFixed(2); color: "white"; font.pixelSize: 11 }
                    Rectangle { width: parent.width; height: 1; color: "#444"; }
                    Text {
                        text: robotController.slamController && robotController.slamController.hasData
                            ? "X: " + robotController.slamController.posX.toFixed(0) + " mm"
                            : "SLAM: \u2014"
                        color: "#8cf"; font.pixelSize: 11
                    }
                    Text {
                        text: robotController.slamController && robotController.slamController.hasData
                            ? "Y: " + robotController.slamController.posY.toFixed(0) + " mm"
                            : ""
                        color: "#8cf"; font.pixelSize: 11
                    }
                    Text {
                        text: robotController.slamController && robotController.slamController.hasData
                            ? "\u03B8: " + robotController.slamController.posTheta.toFixed(1) + "\u00B0"
                            : ""
                        color: "#8cf"; font.pixelSize: 11
                    }
                }
            }

            // Lidar + Map mini displays — bottom-left
            Row {
                anchors.bottom: parent.bottom; anchors.left: parent.left
                anchors.margins: 10; spacing: 6

                LidarDisplay {
                    id: lidarDisplay
                    controller: robotController.lidarController ?? null
                }

                MapDisplay {
                    id: mapDisplay
                    controller: robotController.slamController ?? null
                }
            }

            // Artificial horizon
            ArtificialHorizon {
                id: artificialHorizon
                anchors.centerIn: parent
                roll:  robotController.gyroController.latestX
                pitch: robotController.gyroController.latestY
            }

            // Help text
            Rectangle {
                width: 400; height: 100
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: 10
                color: "black"; opacity: 0.7; radius: 8
                border.color: "white"; border.width: 1
                Column {
                    anchors.centerIn: parent; spacing: 5
                    Text { text: "Movement Controls:"; color: "white"; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                     Text { text: "W/S - Forward/Backward  |  A/D - Strafe Left/Right  |  Q/E - Rotate Left/Right"; color: "white"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                     Text { text: "I/K - Pitch Up/Down  |  J/L - Roll Left/Right  |  R-click on orient: reset to 0"; color: "#80c080"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                     Text { text: "T - Object Tracking  |  +/- - Height Up/Down  |  N - NAV mode  |  Z/C - Trajectory (Lin/Cyc)"; color: "white"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            // ── Pitch/Roll 2-axis control (left of speed joystick) ──
            Item {
                id: orientPanel
                anchors.bottom: parent.bottom; anchors.right: controlPanel.left
                anchors.rightMargin: 20
                anchors.bottomMargin: 10

                readonly property int jsSize:     130
                readonly property int slimW:       26
                readonly property int gap:          4
                readonly property int knobR:       11
                readonly property real halfTravel: (jsSize - knobR * 2) / 2
                readonly property real maxAngle:   30.0

                width:  jsSize + gap + slimW
                height: jsSize + gap + slimW

                Rectangle {
                    id: orientJsPane
                    x: 0; y: 0
                    width: orientPanel.jsSize; height: orientPanel.jsSize
                    color: "#1a1a1a"; border.color: "#4a664a"; border.width: 1; radius: 6; clip: true

                    Rectangle { anchors.centerIn: parent; width: parent.width; height: 1; color: "#2a3a2a" }
                    Rectangle { anchors.centerIn: parent; width: 1; height: parent.height; color: "#2a3a2a" }

                    Text { anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; margins: 3 }
                        text: "PITCH"; color: "#407040"; font.pixelSize: 8 }
                    Text { anchors { bottom: parent.bottom; right: parent.right; margins: 3 }
                        text: "R/L"; color: "#407040"; font.pixelSize: 7 }

                    Rectangle {
                        id: orientKnob
                        width:  orientPanel.knobR * 2; height: orientPanel.knobR * 2; radius: orientPanel.knobR
                        x: orientJsPane.width  / 2 - orientPanel.knobR + (robotController.bodyRoll  / orientPanel.maxAngle) * orientPanel.halfTravel
                        y: orientJsPane.height / 2 - orientPanel.knobR - (robotController.bodyPitch / orientPanel.maxAngle) * orientPanel.halfTravel
                        color: (Math.abs(robotController.bodyRoll)  < 0.1 &&
                                Math.abs(robotController.bodyPitch) < 0.1) ? "#336633" : "#66aa66"
                    }

                    MouseArea {
                        id: orientMA; anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed:         function(mouse) { applyOrient(mouse) }
                        onPositionChanged: function(mouse) {
                            if (orientMA.pressedButtons & Qt.LeftButton) applyOrient(mouse)
                        }
                        function applyOrient(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                robotController.bodyPitch = 0.0
                                robotController.bodyRoll  = 0.0
                                return
                            }
                            var cx = orientJsPane.width  / 2
                            var cy = orientJsPane.height / 2
                            var ht = orientPanel.halfTravel
                            var ma = orientPanel.maxAngle
                            robotController.bodyRoll  = Math.max(-ma, Math.min(ma, (mouse.x - cx) / ht * ma))
                            robotController.bodyPitch = Math.max(-ma, Math.min(ma, (cy - mouse.y) / ht * ma))
                        }
                    }
                }

                Rectangle {
                    id: orientLabel
                    x: 0; y: orientPanel.jsSize + orientPanel.gap
                    width: orientPanel.jsSize + orientPanel.gap + orientPanel.slimW; height: orientPanel.slimW
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Pitch: " + robotController.bodyPitch.toFixed(1) + "\u00B0  |  Roll: " + robotController.bodyRoll.toFixed(1) + "\u00B0"
                        color: "#60a060"; font.pixelSize: 9
                    }
                }
            }

            // ── Joystick + rotation + height controls (bottom-right) ──
            Item {
                id: controlPanel
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.margins: 10

                readonly property int jsSize:     180
                readonly property int slimW:       30
                readonly property int gap:          4
                readonly property int knobR:       13
                readonly property real halfTravel: (jsSize - knobR * 2) / 2

                width:  jsSize + gap + slimW
                height: jsSize + gap + slimW

                Rectangle {
                    id: joystickPane
                    x: 0; y: 0
                    width:  controlPanel.jsSize; height: controlPanel.jsSize
                    color: "#1a1a1a"; border.color: "#4a4a4a"; border.width: 1; radius: 6; clip: true

                    Rectangle { anchors.centerIn: parent; width: parent.width; height: 1; color: "#2a2a2a" }
                    Rectangle { anchors.centerIn: parent; width: 1; height: parent.height; color: "#2a2a2a" }

                    Text { anchors { bottom: parent.bottom; right: parent.right; margins: 4 }
                        text: "MOVE"; color: "#505050"; font.pixelSize: 9 }

                    Rectangle {
                        id: jsKnob
                        width:  controlPanel.knobR * 2; height: controlPanel.knobR * 2; radius: controlPanel.knobR
                        x: joystickPane.width  / 2 - controlPanel.knobR + (robotController.strafeSpeed  / 10.0) * controlPanel.halfTravel
                        y: joystickPane.height / 2 - controlPanel.knobR - (robotController.forwardSpeed / 10.0) * controlPanel.halfTravel
                        color: (Math.abs(robotController.strafeSpeed)  < 0.01 &&
                                Math.abs(robotController.forwardSpeed) < 0.01) ? "#cc3333" : "#ddbb00"
                        layer.enabled: true; layer.effect: null
                    }

                    MouseArea {
                        id: joystickMA
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed:         function(mouse) { applyJoystick(mouse) }
                        onPositionChanged: function(mouse) {
                            if (joystickMA.pressedButtons & Qt.LeftButton) applyJoystick(mouse)
                        }
                        function applyJoystick(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                robotController.strafeSpeed = 0.0; robotController.forwardSpeed = 0.0; return
                            }
                            var cx = joystickPane.width  / 2; var cy = joystickPane.height / 2
                            var ht = controlPanel.halfTravel
                            robotController.strafeSpeed  = Math.max(-10.0, Math.min(10.0, (mouse.x - cx) / ht * 10.0))
                            robotController.forwardSpeed = Math.max(-10.0, Math.min(10.0, (cy - mouse.y) / ht * 10.0))
                        }
                    }
                }

                Rectangle {
                    id: rotPane
                    x: 0; y: controlPanel.jsSize + controlPanel.gap
                    width:  controlPanel.jsSize; height: controlPanel.slimW
                    color: "#1a1a1a"; border.color: "#4a4a4a"; border.width: 1; radius: height / 2; clip: true

                    Rectangle { anchors.centerIn: parent; width: 1; height: parent.height * 0.6; color: "#2a2a2a" }
                    Text { anchors { bottom: parent.bottom; right: parent.right; margins: 4 }
                        text: "ROT"; color: "#505050"; font.pixelSize: 8 }

                    Rectangle {
                        id: rotKnob
                        width:  controlPanel.knobR * 2; height: controlPanel.knobR * 2; radius: controlPanel.knobR
                        x: rotPane.width / 2 - controlPanel.knobR - (robotController.rotationSpeed / 3.0) * controlPanel.halfTravel
                        y: rotPane.height / 2 - controlPanel.knobR
                        color: Math.abs(robotController.rotationSpeed) < 0.01 ? "#cc3333" : "#ddbb00"
                    }

                    MouseArea {
                        id: rotMA; anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed:         function(mouse) { applyRot(mouse) }
                        onPositionChanged: function(mouse) {
                            if (rotMA.pressedButtons & Qt.LeftButton) applyRot(mouse)
                        }
                        function applyRot(mouse) {
                            if (mouse.button === Qt.RightButton) { robotController.rotationSpeed = 0.0; return }
                            var cx = rotPane.width / 2
                            robotController.rotationSpeed = Math.max(-3.0, Math.min(3.0, -(mouse.x - cx) / controlPanel.halfTravel * 3.0))
                        }
                    }
                }

                Rectangle {
                    id: heightPane
                    x: controlPanel.jsSize + controlPanel.gap; y: 0
                    width:  controlPanel.slimW; height: controlPanel.jsSize
                    color: "#1a1a1a"; border.color: "#4a4a4a"; border.width: 1; radius: width / 2; clip: true

                    Rectangle { anchors.centerIn: parent; width: parent.width * 0.6; height: 1; color: "#2a2a2a" }
                    Text { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 4 }
                        text: "H"; color: "#505050"; font.pixelSize: 8 }

                    Rectangle {
                        id: heightKnob
                        width:  controlPanel.knobR * 2; height: controlPanel.knobR * 2; radius: controlPanel.knobR
                        property real normH: Math.max(0.0, Math.min(1.0, (robotController.height - 40.0) / 110.0))
                        x: heightPane.width  / 2 - controlPanel.knobR
                        y: heightPane.height / 2 - controlPanel.knobR - (normH - 0.5) * 2.0 * controlPanel.halfTravel
                        color: Math.abs(robotController.height - 50.0) < 2.0 ? "#cc3333" : "#ddbb00"
                    }

                    MouseArea {
                        id: heightMA; anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed:         function(mouse) { applyHeight(mouse) }
                        onPositionChanged: function(mouse) {
                            if (heightMA.pressedButtons & Qt.LeftButton) applyHeight(mouse)
                        }
                        function applyHeight(mouse) {
                            if (mouse.button === Qt.RightButton) { robotController.height = 50.0; return }
                            var cy = heightPane.height / 2
                            var nh = Math.max(0.0, Math.min(1.0, 0.5 + (cy - mouse.y) / (controlPanel.halfTravel * 2.0)))
                            robotController.height = 40.0 + nh * 110.0
                        }
                    }
                }
            }
        }

        // ── In-nav-mode overlay (map inlined, no separate MapDisplay) ──
        Item {
            anchors.fill: parent
            visible: navMode
            clip: true

            // Pannable/zoomable view — map + robot share a single transform
            Item {
                id: navMapView
                anchors.fill: parent
                property real navMapSize: (robotController.slamController ? robotController.slamController.mapSizeMeters : 20.0) || 20.0

                transform: [
                    Translate { x: navPanX; y: navPanY },
                    Scale {
                        origin.x: navMapView.width  / 2
                        origin.y: navMapView.height / 2
                        xScale: navZoom; yScale: navZoom
                    }
                ]

                // Inlined map image
                Image {
                    id: navMapImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    source: robotController.slamController
                        ? "image://map/frame?idx=" + robotController.slamController.mapFrameIndex
                        : ""
                    antialiasing: false
                    smooth: false
                }

                // Fallback text when no SLAM data
                Text {
                    anchors.centerIn: parent
                    color: "#555"
                    font.pixelSize: 14
                    text: "SLAM: no data"
                    visible: !(robotController.slamController && robotController.slamController.hasData)
                    z: 2
                }

                // Robot circle — image-local coords (transform inherited from navMapView)
                Rectangle {
                    id: navRobotCircle
                    visible: robotController.slamController && robotController.slamController.hasData
                    color: "transparent"
                    border.color: "#00aaff"
                    border.width: 3

                    property real pw:  navMapImage.paintedWidth  || 0
                    property real ph:  navMapImage.paintedHeight || 0
                    property real ppx: (navMapImage.width - pw) / 2 || 0
                    property real ppy: (navMapImage.height - ph) / 2 || 0

                    property real mapSz: Math.max(navMapView.navMapSize, 1)

                    property real robotR: {
                        if (!robotController.slamController || !robotController.slamController.hasData || pw <= 0) return 6
                        return Math.max(4, 0.3 * pw / mapSz * 1.0)
                    }

                    width:  robotR * 2
                    height: robotR * 2
                    radius: robotR
                    x: ppx + (robotController.slamController.posX / 1000.0) * pw / mapSz - robotR
                    y: ppy + (robotController.slamController.posY / 1000.0) * ph / mapSz - robotR
                }

                // Direction arrow inside the robot circle
                Image {
                    id: navRobotArrow
                    visible: robotController.slamController && robotController.slamController.hasData
                    source: "arrow.svg"
                    sourceSize.width:  24
                    sourceSize.height: 30
                    smooth: true

                    property real pw:  navMapImage.paintedWidth  || 0
                    property real ph:  navMapImage.paintedHeight || 0
                    property real ppx: (navMapImage.width - pw) / 2 || 0
                    property real ppy: (navMapImage.height - ph) / 2 || 0

                    property real mapSz: Math.max(navMapView.navMapSize, 1)

                    x: ppx + (robotController.slamController.posX / 1000.0) * pw / mapSz - width  / 2
                    y: ppy + (robotController.slamController.posY / 1000.0) * ph / mapSz - height / 2

                    transform: Rotation {
                        origin.x: navRobotArrow.width  / 2
                        origin.y: navRobotArrow.height / 2
                        angle: (robotController.slamController ? robotController.slamController.posTheta : 0)
                    }
                }
            }
        
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 40
                color: "#1a1a1a"
                opacity: 0.8
                z: 5

                Row {
                    anchors.left: parent.left; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 70; height: 30; radius: 4
                        color: "#662222"; border.color: "#ff4444"; border.width: 1
                        Text { anchors.centerIn: parent; text: "BACK"; color: "white"; font.bold: true; font.pixelSize: 11 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainWindow.setNavMode(false)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NAVIGATION MODE"
                        color: "#ffcc00"; font.bold: true; font.pixelSize: 14
                    }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80; height: 30; radius: 4
                    color: "#334466"; border.color: "#5588cc"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Reset View"; color: "white"; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { navPanX = 0; navPanY = 0; navZoom = 1.0 }
                    }
                }
            }

            // Mouse area for pan, zoom, navigate (on top of map, below bars)
            MouseArea {
                id: navMapMouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: navDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                z: 3

                property real dragStartX: 0; property real dragStartY: 0
                property real dragPanX: 0; property real dragPanY: 0
                property bool navDragging: false

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton && robotController.slamController && robotController.slamController.hasData) {
                        var iw = navMapImage.width, ih = navMapImage.height
                        var pw = navMapImage.paintedWidth, ph = navMapImage.paintedHeight
                        var px = navMapImage.paintedX, py = navMapImage.paintedY
                        if (pw <= 0 || ph <= 0) return
                        var ms = robotController.slamController.mapSizeMeters
                        var lx = (mouse.x - navPanX - iw / 2) / navZoom + iw / 2
                        var ly = (mouse.y - navPanY - ih / 2) / navZoom + ih / 2
                        var wx = (lx - px) * ms / pw * 1000.0
                        var wy = (ly - py) * ms / ph * 1000.0
                        robotController.sendMoveToPoint(wx, wy)
                        return
                    }
                    dragStartX = mouse.x; dragStartY = mouse.y
                    dragPanX = navPanX; dragPanY = navPanY
                    navDragging = true
                }

                onPositionChanged: function(mouse) {
                    if (navDragging && (pressedButtons & Qt.LeftButton)) {
                        navPanX = dragPanX + (mouse.x - dragStartX)
                        navPanY = dragPanY + (mouse.y - dragStartY)
                    }
                }

                onReleased: { navDragging = false }

                onWheel: function(wheel) {
                    var oldZoom = navZoom
                    var f = wheel.angleDelta.y > 0 ? 1.1 : 1.0 / 1.1
                    var newZoom = Math.max(0.3, Math.min(10.0, oldZoom * f))
                    var mx = wheel.x / navMapMouseArea.width
                    var my = wheel.y / navMapMouseArea.height
                    var wx = (mx - 0.5) * navMapMouseArea.width / oldZoom - navPanX / oldZoom
                    var wy = (my - 0.5) * navMapMouseArea.height / oldZoom - navPanY / oldZoom
                    navZoom = newZoom
                    navPanX = -(wx * newZoom - (mx - 0.5) * navMapMouseArea.width)
                    navPanY = -(wy * newZoom - (my - 0.5) * navMapMouseArea.height)
                }
            }

            // HUD: robot coordinate + state at bottom
            Rectangle {
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                height: 36
                color: "#1a1a1a"; opacity: 0.8
                z: 5

                Row {
                    anchors.centerIn: parent; spacing: 30
                    Text { color: "#aaa"; font.pixelSize: 11
                        text: "X: " + (robotController.slamController ? robotController.slamController.posX.toFixed(0) : "—") + " mm" }
                    Text { color: "#aaa"; font.pixelSize: 11
                        text: "Y: " + (robotController.slamController ? robotController.slamController.posY.toFixed(0) : "—") + " mm" }
                    Text { color: "#aaa"; font.pixelSize: 11
                        text: "\u03B8: " + (robotController.slamController ? robotController.slamController.posTheta.toFixed(1) : "—") + "\u00B0" }
                    Text { color: "#aaa"; font.pixelSize: 11
                        text: "Zoom: \u00D7" + navZoom.toFixed(1) }
                }
            }
        }

        // ── Keyboard — global (works in both modes) ──
        Keys.onPressed: function(event) {
            switch(event.key) {
                case Qt.Key_N:
                    mainWindow.setNavMode(!navMode)
                    break
                case Qt.Key_W: case Qt.Key_S:
                case Qt.Key_A: case Qt.Key_D:
                case Qt.Key_Q: case Qt.Key_E:
                case Qt.Key_T:
                 case Qt.Key_Z: case Qt.Key_C:
                 case Qt.Key_Plus: case Qt.Key_Equal: case Qt.Key_Minus:
                 case Qt.Key_I: case Qt.Key_K:
                 case Qt.Key_J: case Qt.Key_L:
                     if (navMode) break
                    // fall through
                default:
                    break
            }
            if (navMode) return
            switch(event.key) {
                case Qt.Key_W: robotController.forwardSpeed = 10.0; break
                case Qt.Key_S: robotController.forwardSpeed = -10.0; break
                case Qt.Key_A: robotController.strafeSpeed = -10.0; break
                case Qt.Key_D: robotController.strafeSpeed = 10.0; break
                case Qt.Key_Q: robotController.rotationSpeed = -3.0; break
                case Qt.Key_E: robotController.rotationSpeed = 3.0; break
                case Qt.Key_T: robotController.setObjectTracking(!robotController.objectTracking); break
                case Qt.Key_Z: robotController.trajectoryType = 0; break
                case Qt.Key_C: robotController.trajectoryType = 1; break
                 case Qt.Key_Plus:
                 case Qt.Key_Equal: robotController.height = Math.min(robotController.height + 5.0, 150.0); break
                 case Qt.Key_Minus: robotController.height = Math.max(robotController.height - 5.0, 40.0); break
                 case Qt.Key_I: robotController.bodyPitch = Math.min(robotController.bodyPitch + 5.0, 30.0); break
                 case Qt.Key_K: robotController.bodyPitch = Math.max(robotController.bodyPitch - 5.0, -30.0); break
                 case Qt.Key_J: robotController.bodyRoll  = Math.max(robotController.bodyRoll  - 5.0, -30.0); break
                 case Qt.Key_L: robotController.bodyRoll  = Math.min(robotController.bodyRoll  + 5.0, 30.0); break
             }
        }
        
        Keys.onReleased: function(event) {
            if (navMode) return
            switch(event.key) {
                 case Qt.Key_W: case Qt.Key_S: robotController.forwardSpeed = 0.0; break
                 case Qt.Key_A: case Qt.Key_D: robotController.strafeSpeed = 0.0; break
                 case Qt.Key_Q: case Qt.Key_E: robotController.rotationSpeed = 0.0; break
                 case Qt.Key_I: case Qt.Key_K:
                 case Qt.Key_J: case Qt.Key_L: break
            }
        }
    }
}
