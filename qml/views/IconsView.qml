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

    readonly property int iconSize: {
        if (viewMode === "xlarge") return 128
        if (viewMode === "large")  return 64
        if (viewMode === "medium") return 40
        return 16
    }

    cellWidth:  viewMode === "xlarge" ? 180 : viewMode === "large" ? 116 : viewMode === "medium" ? 90 : 110
    cellHeight: viewMode === "xlarge" ? 180 : viewMode === "large" ? 112 : viewMode === "medium" ? 88 : 22
    clip: true

    delegate: Rectangle {
        width:  GridView.view.cellWidth  - 6
        height: GridView.view.cellHeight - 6
        color:  root.selectedIds[modelData.id] ? root.pal.selection
              : tileArea.containsMouse          ? root.pal.accentSoft : "transparent"
        border.color: root.selectedIds[modelData.id] ? root.pal.selectionBorder : "transparent"
        radius: 3

        // Normal layout: icon on top, label below (xlarge/large/medium)
        ColumnLayout {
            visible: root.viewMode !== "small"
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            clip: true

            Image {
                Layout.alignment: Qt.AlignHCenter
                source: modelData.previewSrc || modelData.iconSrc || ""
                Layout.preferredWidth:  root.iconSize
                Layout.preferredHeight: root.iconSize
                sourceSize.width:  root.iconSize
                sourceSize.height: root.iconSize
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

        // Small layout: icon left, label right
        RowLayout {
            visible: root.viewMode === "small"
            anchors.fill: parent
            anchors.leftMargin: 4
            spacing: 4

            Image {
                source: modelData.iconSrc || ""
                Layout.preferredWidth:  16
                Layout.preferredHeight: 16
                sourceSize.width:  16
                sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignVCenter
            }
            Label {
                Layout.fillWidth: true
                text: modelData.name
                color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    root.itemClicked(modelData,
                        !!(mouse.modifiers & Qt.ControlModifier),
                        !!(mouse.modifiers & Qt.ShiftModifier))
                else if (mouse.button === Qt.RightButton)
                    root.contextMenuRequested(modelData)
            }
            onDoubleClicked: root.itemDoubleClicked(modelData)
        }
    }
}
