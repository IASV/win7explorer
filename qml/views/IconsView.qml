import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridView {
    id: root
    property var pal
    property var selectedIds: ({})
    property string viewMode: "large"
    property string renamingId: ""
    property bool   showContentPreviews: true

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)
    signal emptyAreaClicked()
    signal renameCommitted(string id, string newName)
    signal renameCancelled()

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: function(point) {
            var idx = root.indexAt(point.position.x + root.contentX,
                                   point.position.y + root.contentY)
            if (idx < 0) root.emptyAreaClicked()
        }
    }

    readonly property int iconSize: {
        if (viewMode === "xlarge") return 128
        if (viewMode === "large")  return 64
        if (viewMode === "medium") return 40
        return 16
    }

    cellWidth:  viewMode === "xlarge" ? 180 : viewMode === "large" ? 116 : viewMode === "medium" ? 90 : 110
    cellHeight: viewMode === "xlarge" ? 180 : viewMode === "large" ? 112 : viewMode === "medium" ? 88 : 22
    clip: true
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

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
                source: root.showContentPreviews
                        ? (modelData.previewSrc || modelData.iconSrc || "")
                        : (modelData.iconSrc || "")
                Layout.preferredWidth:  root.iconSize
                Layout.preferredHeight: root.iconSize
                sourceSize.width:  root.iconSize
                sourceSize.height: root.iconSize
                fillMode: Image.PreserveAspectFit
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Label {
                    anchors.fill: parent
                    visible: modelData.id !== root.renamingId
                    text: modelData.name
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                TextField {
                    anchors.fill: parent
                    visible: modelData.id === root.renamingId
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    background: Rectangle { color: "white"; border.color: "#0078d7"; border.width: 1; radius: 1 }
                    padding: 1; selectByMouse: true
                    Keys.onReturnPressed: { var n = text; root.renameCommitted(modelData.id, n) }
                    Keys.onEscapePressed: root.renameCancelled()
                    onActiveFocusChanged: if (!activeFocus && visible) root.renameCancelled()
                    onVisibleChanged: if (visible) { text = modelData.name; selectAll(); forceActiveFocus() }
                }
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

            Item {
                Layout.fillWidth: true
                implicitHeight: 16

                Label {
                    anchors.fill: parent
                    visible: modelData.id !== root.renamingId
                    text: modelData.name
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                TextField {
                    anchors.fill: parent
                    visible: modelData.id === root.renamingId
                    font.pixelSize: 11
                    background: Rectangle { color: "white"; border.color: "#0078d7"; border.width: 1; radius: 1 }
                    padding: 0; leftPadding: 2; selectByMouse: true
                    Keys.onReturnPressed: { var n = text; root.renameCommitted(modelData.id, n) }
                    Keys.onEscapePressed: root.renameCancelled()
                    onActiveFocusChanged: if (!activeFocus && visible) root.renameCancelled()
                    onVisibleChanged: if (visible) { text = modelData.name; selectAll(); forceActiveFocus() }
                }
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            enabled: modelData.id !== root.renamingId
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
