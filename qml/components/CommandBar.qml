import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

// ═══════════════════════════════════════════════════
// Command Bar: Organizar ▾ | context buttons... | Views ▾ | ?
// Changes buttons depending on content context
// ═══════════════════════════════════════════════════
Rectangle {
    id: cmdBar

    signal newFolderRequested

    gradient: Gradient {
        GradientStop { position: 0.0; color: Win7Theme.cmdBarGradientTop }
        GradientStop { position: 1.0; color: Win7Theme.cmdBarGradientBottom }
    }

    // Top border
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Win7Theme.cmdBarBorderTop
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 4
        spacing: 0

        // ── Organizar dropdown ──
        CmdBarButton {
            text: "Organizar ▾"
            isBold: false
        }

        // ── Separator ──
        CmdBarSeparator {}

        // ── Context buttons (change based on selection) ──
        CmdBarButton {
            text: "Incluir en biblioteca ▾"
            visible: !fileSystemBackend.selectedFileInfo.isDir ||
                     fileSystemBackend.selectedCount === 0
        }

        CmdBarButton {
            text: "Compartir con ▾"
        }

        CmdBarSeparator { visible: true }

        CmdBarButton {
            text: "Grabar"
        }

        CmdBarButton {
            text: "Nueva carpeta"
            onClicked: cmdBar.newFolderRequested()
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // ── Right side: Views dropdown + Help ──
        CmdBarSeparator {}

        // Views slider button (simplified as dropdown for now)
        Rectangle {
            width: 24
            height: parent.height - 4
            radius: 2
            color: viewsBtnMa.containsPress ? Win7Theme.cmdBarBtnPressed
                 : viewsBtnMa.containsMouse ? Win7Theme.cmdBarBtnHover
                 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "☰"
                font.pixelSize: 14
                color: Win7Theme.cmdBarText
            }

            MouseArea {
                id: viewsBtnMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: viewsMenu.open()
            }

            ToolTip.text: "Cambiar la vista"
            ToolTip.visible: viewsBtnMa.containsMouse

            Menu {
                id: viewsMenu
                y: parent.height

                MenuItem { text: "Iconos muy grandes" }
                MenuItem { text: "Iconos grandes" }
                MenuItem { text: "Iconos medianos" }
                MenuItem { text: "Iconos pequeños" }
                MenuSeparator {}
                MenuItem { text: "Lista" }
                MenuItem { text: "Detalles" }
                MenuItem { text: "Mosaicos" }
                MenuItem { text: "Contenido" }
            }
        }

        // Preview pane toggle
        Rectangle {
            width: 24
            height: parent.height - 4
            radius: 2
            color: previewBtnMa.containsPress ? Win7Theme.cmdBarBtnPressed
                 : previewBtnMa.containsMouse ? Win7Theme.cmdBarBtnHover
                 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "☐"
                font.pixelSize: 13
                color: Win7Theme.cmdBarText
            }

            MouseArea {
                id: previewBtnMa
                anchors.fill: parent
                hoverEnabled: true
            }

            ToolTip.text: "Panel de vista previa"
            ToolTip.visible: previewBtnMa.containsMouse
        }

        // Help button
        Rectangle {
            width: 24
            height: parent.height - 4
            radius: 12
            color: helpBtnMa.containsPress ? Win7Theme.cmdBarBtnPressed
                 : helpBtnMa.containsMouse ? Win7Theme.cmdBarBtnHover
                 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "?"
                font.pixelSize: 14
                font.bold: true
                color: "#3B72A9"
            }

            MouseArea {
                id: helpBtnMa
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    // ═══ Reusable Command Bar Button ═══
    component CmdBarButton: Rectangle {
        property alias text: label.text
        property bool isBold: false
        signal clicked

        implicitWidth: label.implicitWidth + 16
        height: parent.height - 4
        Layout.alignment: Qt.AlignVCenter
        radius: 2
        color: cmdBtnMa.containsPress ? Win7Theme.cmdBarBtnPressed
             : cmdBtnMa.containsMouse ? Win7Theme.cmdBarBtnHover
             : "transparent"

        Text {
            id: label
            anchors.centerIn: parent
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeNormal + 2
            font.bold: isBold
            color: Win7Theme.cmdBarText
        }

        MouseArea {
            id: cmdBtnMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    // ═══ Separator ═══
    component CmdBarSeparator: Rectangle {
        width: 1
        height: parent.height - 8
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        color: Win7Theme.cmdBarSeparator
    }
}
