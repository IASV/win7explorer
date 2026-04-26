import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var    pal
    property string message: ""

    visible: message.length > 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40
    color: pal.panel
    border.color: pal.border
    radius: 20
    implicitWidth:  toastLbl.implicitWidth + 36
    implicitHeight: 36

    Label {
        id: toastLbl
        anchors.centerIn: parent
        text: root.message
        color: root.pal.text; font.pixelSize: 12
    }
}
