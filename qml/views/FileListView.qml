import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    id: root
    property var pal
    property var selectedIds: ({})

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)

    clip: true

    delegate: Rectangle {
        width:  ListView.view.width
        height: 22
        color:  root.selectedIds[modelData.id] ? root.pal.selection
              : rowArea.containsMouse          ? root.pal.accentSoft : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            spacing: 6
            Image {
                source: modelData.iconSrc || ""
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                fillMode: Image.PreserveAspectFit
            }
            Label {
                text: modelData.name
                color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                root.itemClicked(modelData,
                    !!(mouse.modifiers & Qt.ControlModifier),
                    !!(mouse.modifiers & Qt.ShiftModifier))
                if (mouse.button === Qt.RightButton)
                    root.contextMenuRequested(modelData)
            }
            onDoubleClicked: root.itemDoubleClicked(modelData)
        }
    }
}
