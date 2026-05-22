import QtQuick
import QtQuick.Layouts

/**
 * @brief Top-right sensor data HUD block.
 * Shows battery voltage, CPU temperature, system status and IMU readings.
 */
Rectangle {
    id: root
    color: "#bb000000"
    radius: 8
    border.color: "#55ffffff"
    border.width: 1

    required property var telemetryData

    // Voltage thresholds (V)
    readonly property real voltLow:  10.5
    readonly property real voltWarn: 11.0

    function voltageColor(v) {
        if (v <= 0)       return "#888888"   // no data
        if (v < voltLow)  return "#ff4444"   // critical
        if (v < voltWarn) return "#ffaa00"   // warning
        return "#44ff88"                     // ok
    }

    function tempColor(t) {
        if (t <= 0)   return "#888888"
        if (t >= 75)  return "#ff4444"
        if (t >= 60)  return "#ffaa00"
        return "#44ccff"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // ── Header ──────────────────────────────────────────────────
        Text {
            text: "SENSORS"
            color: "#aaaaaa"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.5
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#444444" }

        // ── Battery Voltage ─────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "\u26A1"   // ⚡
                color: voltageColor(telemetryData["battery_voltage"] || 0)
                font.pixelSize: 14
            }

            Text {
                text: "Battery"
                color: "#aaaaaa"
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            Text {
                readonly property real v: telemetryData["battery_voltage"] || 0
                text: v > 0 ? v.toFixed(2) + " V" : "-- V"
                color: voltageColor(v)
                font.pixelSize: 13
                font.bold: true
            }
        }

        // Battery bar
        Rectangle {
            Layout.fillWidth: true
            height: 5
            radius: 2
            color: "#333333"

            Rectangle {
                readonly property real v: telemetryData["battery_voltage"] || 0
                // Map 10.0 V (empty) … 12.6 V (full) to 0…1
                readonly property real pct: v > 0 ? Math.max(0, Math.min(1, (v - 10.0) / 2.6)) : 0
                width: parent.width * pct
                height: parent.height
                radius: 2
                color: voltageColor(v)
                Behavior on width { SmoothedAnimation { duration: 400 } }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }

        // ── CPU Temperature ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "\uD83C\uDF21"   // 🌡 (thermometer emoji, two code units)
                color: tempColor(telemetryData["cpu_temperature"] || 0)
                font.pixelSize: 13
            }

            Text {
                text: "CPU Temp"
                color: "#aaaaaa"
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            Text {
                readonly property real t: telemetryData["cpu_temperature"] || 0
                text: t > 0 ? t.toFixed(1) + " \u00B0C" : "-- \u00B0C"
                color: tempColor(t)
                font.pixelSize: 13
                font.bold: true
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }

        // ── IMU (Gyro roll / pitch) ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Roll"
                color: "#aaaaaa"
                font.pixelSize: 11
                Layout.preferredWidth: 28
            }
            Text {
                readonly property var g: telemetryData["gyro"]
                text: g ? g.x.toFixed(1) + "\u00B0" : "--\u00B0"
                color: "#dddddd"
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Pitch"
                color: "#aaaaaa"
                font.pixelSize: 11
                Layout.preferredWidth: 32
            }
            Text {
                readonly property var g: telemetryData["gyro"]
                text: g ? g.y.toFixed(1) + "\u00B0" : "--\u00B0"
                color: "#dddddd"
                font.pixelSize: 12
                font.bold: true
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }

        // ── System Status ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                width: 8; height: 8; radius: 4
                color: {
                    var s = telemetryData["status"] || ""
                    return s === "running" ? "#44ff88"
                         : s === ""        ? "#888888"
                         : "#ffaa00"
                }
            }

            Text {
                text: "Status"
                color: "#aaaaaa"
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            Text {
                text: telemetryData["status"] || "unknown"
                color: "#dddddd"
                font.pixelSize: 12
                font.bold: true
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }

        // ── Connection Speed ────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Bytes per second
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "📊"   // chart emoji
                    font.pixelSize: 12
                }

                Text {
                    text: "RX Bytes/s"
                    color: "#aaaaaa"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                Text {
                    readonly property var bytes: telemetryData["bytes_received_per_sec"] || 0
                    text: bytes > 0 ? (bytes / 1024).toFixed(1) + " KB/s" : "-- KB/s"
                    color: "#dddddd"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            // Messages per second
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "📨"   // inbox emoji
                    font.pixelSize: 12
                }

                Text {
                    text: "RX Msg/s"
                    color: "#aaaaaa"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                Text {
                    readonly property var msgs: telemetryData["messages_received_per_sec"] || 0
                    text: msgs > 0 ? msgs + " msg/s" : "-- msg/s"
                    color: "#dddddd"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }
}
