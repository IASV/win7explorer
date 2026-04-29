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
    spacing: 0
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    delegate: Rectangle {
        width:  ListView.view.width
        height: 64
        color:  root.selectedIds[modelData.id] ? root.pal.selection
              : cvArea.containsMouse           ? root.pal.accentSoft : "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 1
            color: root.pal.borderSoft
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 14

            Image {
                source: modelData.previewSrc || modelData.iconSrc || ""
                Layout.preferredWidth: 44; Layout.preferredHeight: 44
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Label {
                    text: modelData.name
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                    font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Label {
                    text: {
                        var parts = [modelData.typeStr || ""]
                        if (modelData.size)     parts.push(modelData.size)
                        if (modelData.modified) parts.push("Modificado: " + modelData.modified)
                        return parts.filter(Boolean).join("  ·  ")
                    }
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
        }

        MouseArea {
            id: cvArea
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
