import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: settingsPage
    anchors.fill: parent

    signal back()

    function requestSettings() {
        robotController.requestSettings()
    }

    // Read current value from robotController.settingsData with fallback
    function getVal(key, fallback) {
        var v = robotController.settingsData[key]
        return v !== undefined ? v : fallback
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#1a1a1a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Rectangle {
                    width: 70; height: 30; radius: 4
                    color: "#662222"; border.color: "#ff4444"; border.width: 1
                    Text { anchors.centerIn: parent; text: "BACK"; color: "white"; font.bold: true; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; onClicked: back() }
                }

                Text {
                    text: "ROBOT SETTINGS"
                    color: "#ffcc00"; font.bold: true; font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 80; height: 30; radius: 4
                    color: "#334466"; border.color: "#5588cc"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Refresh"; color: "white"; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; onClicked: requestSettings() }
                }

                Rectangle {
                    id: applyBtn
                    width: 70; height: 30; radius: 4
                    color: "#226622"; border.color: "#44ff44"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Apply"; color: "white"; font.bold: true; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var map = {}
                            // Walk the content column for all SettingsSlider instances
                            var children = contentCol.children
                            for (var i = 0; i < children.length; ++i) {
                                var ch = children[i]
                                // Each SettingsSlider has a property 'key' and 'intMode'
                                if (ch.key !== undefined) {
                                    var sl = ch
                                    map[sl.key] = sl.intMode
                                        ? Math.round(sl.sliderValue)
                                        : sl.sliderValue
                                }
                            }
                            robotController.sendSettingsSet(map)
                        }
                    }
                }
            }
        }

        // ── Scrollable content ──
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

            Item {
                width: settingsPage.width - 20
                height: contentCol.implicitHeight + 20
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    id: contentCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 16

                    // ── Blob Tracking Section ──
                    SectionHeader { text: "Blob Tracking" }

                    SettingsSlider {
                        id: blobKp
                        label: "P Gain (KP)"; key: "blob_kp"
                        from: 0; to: 100; stepSize: 0.5
                        defaultValue: 20.0
                    }
                    SettingsSlider {
                        id: blobKi
                        label: "I Gain (KI)"; key: "blob_ki"
                        from: 0; to: 20; stepSize: 0.1
                        defaultValue: 2.0
                    }
                    SettingsSlider {
                        label: "Max Pitch (deg)"; key: "blob_max_pitch_deg"
                        from: 5; to: 60; stepSize: 1
                        defaultValue: 30.0
                    }
                    SettingsSlider {
                        label: "Pitch Dead Zone"; key: "blob_pitch_dead_zone"
                        from: 0; to: 0.2; stepSize: 0.005
                        defaultValue: 0.02
                    }
                    SettingsSlider {
                        label: "Rot Dead Zone"; key: "blob_rot_dead_zone"
                        from: 0; to: 0.3; stepSize: 0.005
                        defaultValue: 0.05
                    }
                    SettingsSlider {
                        label: "Max Rotation (deg)"; key: "blob_max_rotation_deg"
                        from: 5; to: 60; stepSize: 1
                        defaultValue: 20.0
                    }
                    SettingsSlider {
                        label: "Min Streak (frames)"; key: "blob_min_streak"
                        from: 0; to: 20; stepSize: 1
                        defaultValue: 3
                    }
                    SettingsSlider {
                        label: "Max Blob Fraction"; key: "blob_max_fraction"
                        from: 0.05; to: 0.8; stepSize: 0.01
                        defaultValue: 0.35
                    }
                    SettingsSlider {
                        label: "Min Blob Area (px)"; key: "blob_min_area"
                        from: 50; to: 2000; stepSize: 10
                        defaultValue: 300
                    }

                    // ── Gait Section ──
                    SectionHeader { text: "Gait" }

                    SettingsSlider {
                        label: "Movement Smoothing"; key: "gait_movement_smoothing"
                        from: 0; to: 1; stepSize: 0.01
                        defaultValue: 0.2
                    }
                    SettingsSlider {
                        label: "Rotation Smoothing"; key: "gait_rotation_smoothing"
                        from: 0; to: 1; stepSize: 0.01
                        defaultValue: 0.5
                    }
                    SettingsSlider {
                        label: "Step Height (mm)"; key: "gait_step_height"
                        from: 5; to: 60; stepSize: 1
                        defaultValue: 20.0
                    }
                    SettingsSlider {
                        label: "Max Step Length (mm)"; key: "gait_max_step_length"
                        from: 5; to: 60; stepSize: 1
                        defaultValue: 25.0
                    }
                    SettingsSlider {
                        label: "Gait Frequency"; key: "gait_frequency"
                        from: 0.01; to: 0.3; stepSize: 0.005
                        defaultValue: 0.08
                    }
                    SettingsSlider {
                        label: "Swing Ratio"; key: "gait_swing_ratio"
                        from: 0.3; to: 0.8; stepSize: 0.01
                        defaultValue: 0.5
                    }

                    // ── Servo Section ──
                    SectionHeader { text: "Servo" }

                    SettingsSlider {
                        label: "Move Time (ms)"; key: "servo_move_time_ms"
                        from: 20; to: 500; stepSize: 5
                        defaultValue: 100
                    }

                    // ── Body Section ──
                    SectionHeader { text: "Body Limits" }

                    SettingsSlider {
                        label: "Max Pitch (deg)"; key: "body_max_pitch_deg"
                        from: 10; to: 60; stepSize: 1
                        defaultValue: 30.0
                    }
                    SettingsSlider {
                        label: "Max Roll (deg)"; key: "body_max_roll_deg"
                        from: 10; to: 60; stepSize: 1
                        defaultValue: 30.0
                    }

                    // Bottom spacer
                    Item { width: 1; height: 20 }
                }
            }
        }
    }

    // ── Helper: Section header ──
    component SectionHeader: Rectangle {
        property string text
        width: parent.width
        height: 28
        color: "#2a2a2a"
        radius: 4
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 8
            text: parent.text
            color: "#ffcc00"; font.bold: true; font.pixelSize: 12
        }
    }

    // ── Helper: Slider row ──
    component SettingsSlider: Rectangle {
        property string label
        property string key
        property real from: 0
        property real to: 100
        property real stepSize: 1
        property real defaultValue: 0
        property bool intMode: stepSize >= 1 && stepSize === Math.floor(stepSize)
        property real sliderValue: slider.value

        width: parent.width; height: 32
        color: "#1e1e1e"; radius: 3

        RowLayout {
            anchors.fill: parent; anchors.margins: 4
            spacing: 8

            Text {
                text: label
                color: "#ccc"; font.pixelSize: 10
                Layout.preferredWidth: 140
                elide: Text.ElideRight
            }

            Slider {
                id: slider
                from: from; to: to; stepSize: stepSize
                Layout.fillWidth: true
                // Read initial value from settings data
                value: {
                    var v = robotController.settingsData[key]
                    return v !== undefined ? v : defaultValue
                }

                onValueChanged: {
                    valText.text = intMode ? Math.round(value).toString() : value.toFixed(3)
                }

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 4
                    radius: 2
                    color: "#444"
                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: "#5588cc"
                    }
                }

                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 16; height: 16; radius: 8
                    color: slider.pressed ? "#88bbff" : "#6699dd"
                    border.color: "#aaa"; border.width: 1
                }

                // Re-read from robotController when settingsData changes
                Connections {
                    target: robotController
                    function onSettingsDataChanged() {
                        var v = robotController.settingsData[key]
                        if (v !== undefined)
                            slider.value = v
                    }
                }
            }

            Text {
                id: valText
                text: "—"
                color: "#88ff88"; font.pixelSize: 11; font.bold: true
                Layout.preferredWidth: 50
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
