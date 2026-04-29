import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    id: root
    property var pal
    property var selectedIds: ({})
    property string renamingId: ""

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)
    signal emptyAreaClicked()
    signal renameCommitted(string id, string newName)
    signal renameCancelled()

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: function(point) {
            var idx = root.indexAt(point.position.x,
                                   point.position.y + root.contentY)
            if (idx < 0) root.emptyAreaClicked()
        }
    }

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

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 18

                    Label {
                        anchors.fill: parent
                        visible: modelData.id !== root.renamingId
                        text: modelData.name
                        color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    TextField {
                        anchors.fill: parent
                        visible: modelData.id === root.renamingId
                        font.pixelSize: 13
                        background: Rectangle { color: "white"; border.color: "#0078d7"; border.width: 1; radius: 1 }
                        padding: 0; leftPadding: 3; selectByMouse: true
                        Keys.onReturnPressed: { var n = text; root.renameCommitted(modelData.id, n) }
                        Keys.onEscapePressed: root.renameCancelled()
                        onActiveFocusChanged: if (!activeFocus && visible) root.renameCancelled()
                        onVisibleChanged: if (visible) { text = modelData.name; selectAll(); forceActiveFocus() }
                    }
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
