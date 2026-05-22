import QtQuick

Rectangle {
    id: root
    width: labelText.width + 28
    height: 26
    radius: 5
    color: active ? "#2ecc71" : "#e74c3c"
    opacity: 0.9
    border.color: "white"
    border.width: 1

    property string label: ""
    property bool active: false

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: "white"
        font.pixelSize: 11
        font.bold: true
    }
}
