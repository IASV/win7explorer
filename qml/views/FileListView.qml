import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Win7 "Lista" — column-major multi-column layout (top-to-bottom, then next column)
Item {
    id: root
    property var pal
    property var model:       []
    property var selectedIds: ({})

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)

    readonly property int cellW: 220
    readonly property int cellH: 22

    // GridView with FlowTopToBottom: items fill top-to-bottom per column
    GridView {
        id: grid
        anchors.fill: parent
        clip: true

        flow:       GridView.FlowTopToBottom
        cellWidth:  root.cellW
        cellHeight: root.cellH

        // Fix height so items wrap to next column after filling one column.
        // The view scrolls horizontally when all columns exceed the viewport width.
        // height is already parent.height from anchors.fill.

        model: root.model

        delegate: Rectangle {
            width:  root.cellW - 2
            height: root.cellH
            color:  root.selectedIds[modelData.id] ? root.pal.selection
                  : rowArea.containsMouse           ? root.pal.accentSoft : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                spacing: 5

                Image {
                    source: modelData.iconSrc || ""
                    Layout.preferredWidth:  16
                    Layout.preferredHeight: 16
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    text: modelData.name
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
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
}
