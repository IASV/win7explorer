import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

// ═══════════════════════════════════════════════════
// Status Bar: Bottom bar with item count info
// ═══════════════════════════════════════════════════
Rectangle {
    id: statusBar
    color: Win7Theme.statusBarBg

    // Top border
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Win7Theme.statusBarBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 20

        // Item count
        Text {
            text: {
                let count = fileSystemBackend.itemCount
                let selected = fileSystemBackend.selectedCount
                let msg = count + " elemento" + (count !== 1 ? "s" : "")
                if (selected > 0)
                    msg += "  |  " + selected + " elemento" +
                           (selected !== 1 ? "s" : "") + " seleccionado" +
                           (selected !== 1 ? "s" : "")
                return msg
            }
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeNormal + 1
            color: Win7Theme.statusBarText
        }

        Item { Layout.fillWidth: true }

        // View mode indicator (right side, like Win7)
        Row {
            spacing: 2

            // Details view button
            StatusViewButton {
                text: "☰"
                isActive: false
                ToolTip.text: "Detalles"
            }

            // Icons view button
            StatusViewButton {
                text: "▦"
                isActive: true
                ToolTip.text: "Iconos grandes"
            }
        }
    }

    // ═══ Status View Button Component ═══
    component StatusViewButton: Rectangle {
        property alias text: label.text
        property bool isActive: false

        width: 22
        height: 18
        radius: 2
        color: isActive ? Win7Theme.selectionBg
             : statusViewMa.containsMouse ? Win7Theme.selectionHoverBg
             : "transparent"
        border.color: isActive ? Win7Theme.selectionBorder
                     : statusViewMa.containsMouse ? Win7Theme.selectionHoverBorder
                     : "transparent"
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: 12
            color: Win7Theme.statusBarText
        }

        MouseArea {
            id: statusViewMa
            anchors.fill: parent
            hoverEnabled: true
        }

        ToolTip.visible: statusViewMa.containsMouse
    }
}
