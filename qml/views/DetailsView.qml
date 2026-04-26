import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var pal
    property var model:       []
    property var selectedIds: ({})
    property string sortBy:  "name"
    property string sortDir: "asc"

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)
    signal sortRequested(string col)

    spacing: 0

    // Column header
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        gradient: Gradient {
            GradientStop { position: 0; color: root.pal.tbar1 }
            GradientStop { position: 1; color: root.pal.tbar2 }
        }
        border.color: root.pal.borderSoft

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: [
                    { id: "name",     label: "Nombre",                  stretch: 3 },
                    { id: "modified", label: "Fecha de modificación",   stretch: 2 },
                    { id: "type",     label: "Tipo",                    stretch: 1 },
                    { id: "size",     label: "Tamaño",                  stretch: 1 }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: modelData.stretch * 100
                    Layout.fillHeight: true
                    color: colHov.containsMouse ? root.pal.accentSoft : "transparent"
                    border.color: root.pal.borderSoft

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        Label {
                            text: modelData.label
                            color: root.sortBy === modelData.id ? root.pal.accent : root.pal.text
                            font.pixelSize: 11; font.bold: true
                            Layout.fillWidth: true
                        }
                        Label {
                            visible: root.sortBy === modelData.id
                            text: root.sortDir === "asc" ? "▲" : "▼"
                            color: root.pal.accent
                            font.pixelSize: 9
                        }
                    }
                    MouseArea {
                        id: colHov
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.sortRequested(modelData.id)
                    }
                }
            }
        }
    }

    // File rows
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.model

        delegate: Rectangle {
            width:  ListView.view.width
            height: 24
            color:  root.selectedIds[modelData.id] ? root.pal.selection
                  : detArea.containsMouse          ? root.pal.accentSoft : "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 300
                    Layout.leftMargin: 8; spacing: 6
                    Image {
                        source: modelData.iconSrc || ""
                        Layout.preferredWidth: 16; Layout.preferredHeight: 16
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        text: modelData.name
                        color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                        font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                    }
                }
                Label { Layout.fillWidth: true; Layout.preferredWidth: 200; Layout.leftMargin: 8
                    text: modelData.modified || "—"
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11 }
                Label { Layout.fillWidth: true; Layout.preferredWidth: 100; Layout.leftMargin: 8
                    text: modelData.typeStr || "—"
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11 }
                Label { Layout.fillWidth: true; Layout.preferredWidth: 100
                    Layout.leftMargin: 8; Layout.rightMargin: 8
                    text: modelData.size || (modelData.type === "folder" ? "" : "—")
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11 }
            }

            MouseArea {
                id: detArea
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
