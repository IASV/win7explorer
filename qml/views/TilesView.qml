import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root
    property var pal
    property var model:       []
    property var selectedIds: ({})
    property string renamingId: ""

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)
    signal emptyAreaClicked()
    signal renameCommitted(string id, string newName)
    signal renameCancelled()
    signal itemDroppedOnFolder(string srcPath, string destFolder)

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy:   ScrollBar.AsNeeded

    Flow {
        width: root.availableWidth
        leftPadding:   8
        rightPadding:  8
        topPadding:    8
        bottomPadding: 8
        spacing: 2

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.emptyAreaClicked()
        }

        Repeater {
            model: root.model

            delegate: Rectangle {
                id: tileDelegate
                width:  190
                height: 55
                radius: 2
                color: root.selectedIds[modelData.id] ? root.pal.selection
                     : tileDrop.containsDrag            ? root.pal.accentSoft
                     : tileArea.containsMouse           ? root.pal.accentSoft : "transparent"
                border.color: tileDrop.containsDrag          ? root.pal.accent
                            : root.selectedIds[modelData.id] ? root.pal.selectionBorder
                            : tileArea.containsMouse          ? root.pal.border : "transparent"

                Drag.active:           tileDrag.active
                Drag.dragType:         Drag.Automatic
                Drag.supportedActions: Qt.MoveAction | Qt.CopyAction
                Drag.mimeData:         ({ "text/uri-list": "file://" + modelData.id })

                DragHandler {
                    id: tileDrag
                    dragThreshold: 8
                    onActiveChanged: if (active) parent.grabToImage(function(r) { parent.Drag.imageSource = r.url })
                }

                DropArea {
                    id: tileDrop
                    anchors.fill: parent
                    enabled: modelData.type === "folder" && !tileDrag.active
                    keys: ["text/uri-list"]
                    onDropped: function(drop) {
                        var url = drop.urls && drop.urls.length > 0 ? drop.urls[0].toString() : ""
                        var src = url.replace(/^file:\/\//, "")
                        if (src && src !== modelData.id)
                            root.itemDroppedOnFolder(src, modelData.id)
                        drop.accept(Qt.MoveAction)
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Image {
                        source: modelData.previewSrc || modelData.iconSrc || ""
                        Layout.preferredWidth:  40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignVCenter
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width:  40
                        sourceSize.height: 40
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 1

                        Item { Layout.fillHeight: true }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 18

                            Label {
                                anchors.fill: parent
                                visible: modelData.id !== root.renamingId
                                text: modelData.name
                                color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            TextField {
                                anchors.fill: parent
                                visible: modelData.id === root.renamingId
                                font.pixelSize: 12
                                background: Rectangle { color: "white"; border.color: "#0078d7"; border.width: 1; radius: 1 }
                                padding: 0; leftPadding: 2; selectByMouse: true
                                Keys.onReturnPressed: { var n = text; root.renameCommitted(modelData.id, n) }
                                Keys.onEscapePressed: root.renameCancelled()
                                onActiveFocusChanged: if (!activeFocus && visible) { var n = text; root.renameCommitted(modelData.id, n) }
                                onVisibleChanged: if (visible) { text = modelData.name; selectAll(); forceActiveFocus() }
                            }
                        }
                        Label {
                            text: modelData.typeStr || ""
                            color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            visible: !!modelData.size
                            text: modelData.size || ""
                            color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                            font.pixelSize: 10
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    enabled: modelData.id !== root.renamingId
                    onClicked: function(mouse) {
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
    }
}
