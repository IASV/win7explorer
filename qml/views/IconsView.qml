import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridView {
    id: root
    property var pal
    property var selectedIds: ({})
    property string viewMode: "large"

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)

    cellWidth:  viewMode === "large" ? 110 : 82
    cellHeight: viewMode === "large" ? 100 : 78
    clip: true

    delegate: Rectangle {
        width:  GridView.view.cellWidth  - 6
        height: GridView.view.cellHeight - 6
        color:  root.selectedIds[modelData.id] ? root.pal.selection
              : tileArea.containsMouse          ? root.pal.accentSoft : "transparent"
        border.color: root.selectedIds[modelData.id] ? root.pal.selectionBorder : "transparent"
        radius: 3

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Image {
                Layout.alignment: Qt.AlignHCenter
                source: modelData.iconSrc || ""
                Layout.preferredWidth:  root.viewMode === "large" ? 64 : 40
                Layout.preferredHeight: root.viewMode === "large" ? 64 : 40
                sourceSize.width:  root.viewMode === "large" ? 64 : 40
                sourceSize.height: root.viewMode === "large" ? 64 : 40
                fillMode: Image.PreserveAspectFit
            }
            Label {
                Layout.fillWidth: true
                text: modelData.name
                color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: tileArea
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
