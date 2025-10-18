import QtQuick
import QtQuick.Layouts

Rectangle {
    id: connectionDialog
    width: 400
    height: 200
    color: "lightgray"
    border.color: "black"
    border.width: 2
    radius: 10
    
    property alias serverIp: ipTextField.text
    
    signal connectClicked(string ip)
    signal cancelClicked()
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        Text {
            text: "Connect to Spider2 Robot"
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            text: "Enter robot IP address:"
            font.pixelSize: 16
        }
        
        Rectangle {
            id: ipTextField
            width: 200
            height: 30
            color: "white"
            border.color: "black"
            border.width: 1
            
            property string text: "192.168.1.100"
            
            Text {
                anchors.centerIn: parent
                text: ipTextField.text
                color: "black"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // For now, just use the default IP
                    connectClicked(ipTextField.text)
                }
            }
        }
        
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
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
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: cancelClicked()
                }
            }
            
            Rectangle {
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
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: connectClicked(ipTextField.text)
                }
            }
        }
    }
}
