import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root
    property var pal
    property var model:       []
    property var selectedIds: ({})

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)

    clip: true

    Column {
        width: root.width
        spacing: 18

        Repeater {
            model: [
                { title: "Unidades de disco duro",
                  filter: function(i){ return i.type === "drive" && i.kind !== "disc" } },
                { title: "Dispositivos con almacenamiento extraíble",
                  filter: function(i){ return i.type === "drive" && i.kind === "disc" } },
                { title: "Ubicaciones de red",
                  filter: function(i){ return i.kind === "pc" || i.kind === "printer" } },
                { title: "Carpetas",
                  filter: function(i){ return i.type === "folder" } }
            ]
            delegate: Column {
                width: root.width
                spacing: 8
                property var subset: root.model ? root.model.filter(modelData.filter) : []
                visible: subset.length > 0

                Label {
                    text: modelData.title + "  (" + parent.subset.length + ")"
                    color: root.pal.accent
                    font.pixelSize: 12; font.bold: true
                    leftPadding: 12
                }

                Flow {
                    width: parent.width
                    spacing: 14
                    leftPadding: 8

                    Repeater {
                        model: parent.parent.subset
                        delegate: Rectangle {
                            width: 260; height: 64
                            color:  root.selectedIds[modelData.id] ? root.pal.selection
                                  : grArea.containsMouse           ? root.pal.accentSoft : "transparent"
                            border.color: root.selectedIds[modelData.id] ? root.pal.selectionBorder : "transparent"
                            radius: 3

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Image {
                                    source: modelData.iconSrc || ""
                                    Layout.preferredWidth: 52; Layout.preferredHeight: 52
                                    fillMode: Image.PreserveAspectFit
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Label {
                                        text: modelData.name
                                        color: root.pal.text; font.pixelSize: 12; font.bold: true
                                    }
                                    Rectangle {
                                        visible: modelData.total !== undefined
                                        Layout.fillWidth: true; Layout.preferredHeight: 6
                                        color: root.pal.borderSoft; radius: 3
                                        Rectangle {
                                            width: parent.width * (modelData.total
                                                ? (modelData.total - modelData.free) / modelData.total : 0)
                                            height: parent.height; radius: 3
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0; color: "#4fd1e8" }
                                                GradientStop { position: 1; color: "#1a8ab8" }
                                            }
                                        }
                                    }
                                    Label {
                                        visible: modelData.total !== undefined
                                        text: modelData.free + " GB libres de " + modelData.total + " GB"
                                        color: root.pal.muted; font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: grArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.itemClicked(modelData, false, false)
                                onDoubleClicked: root.itemDoubleClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
