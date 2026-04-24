import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles/Win7Theme.js" as Win7Theme

// ═══════════════════════════════════════════════════
// Command Bar: Organizar ▾ | context buttons... | Views ▾ | ?
// Changes buttons depending on content context
// ═══════════════════════════════════════════════════
Rectangle {
    id: cmdBar

    // ── Signals for cross-component operations ──
    signal newFolderRequested()
    signal cutRequested()
    signal copyRequested()
    signal pasteRequested()
    signal deleteRequested()
    signal renameRequested()
    signal selectAllRequested()
    signal navPanelToggled()
    signal detailsPanelToggled()
    signal previewPanelToggled()

    // ── State received from main.qml ──
    property bool hasClipboard: false
    property bool hasSelection: fileSystemBackend.selectedCount > 0
    property bool navPanelVisible: true
    property bool detailsPanelVisible: true
    property bool previewPanelVisible: false

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

    // ════════════════════════════════════════
    // Organizar ▾ full dropdown menu (Win7-faithful)
    // ════════════════════════════════════════
    Menu {
        id: organizarMenu
        y: cmdBar.height

        MenuItem {
            text: "Cortar"
            enabled: cmdBar.hasSelection
            onTriggered: cmdBar.cutRequested()
        }
        MenuItem {
            text: "Copiar"
            enabled: cmdBar.hasSelection
            onTriggered: cmdBar.copyRequested()
        }
        MenuItem {
            text: "Pegar"
            enabled: cmdBar.hasClipboard
            onTriggered: cmdBar.pasteRequested()
        }
        MenuSeparator {}
        MenuItem {
            text: "Deshacer"
            enabled: false  // future
        }
        MenuItem {
            text: "Rehacer"
            enabled: false
        }
        MenuItem {
            text: "Seleccionar todo"
            onTriggered: cmdBar.selectAllRequested()
        }
        MenuSeparator {}

        // Diseño submenu
        Menu {
            title: "Diseño"

            MenuItem {
                text: "Panel de navegación"
                checkable: true
                checked: cmdBar.navPanelVisible
                onTriggered: cmdBar.navPanelToggled()
            }
            MenuItem {
                text: "Panel de detalles"
                checkable: true
                checked: cmdBar.detailsPanelVisible
                onTriggered: cmdBar.detailsPanelToggled()
            }
            MenuItem {
                text: "Panel de vista previa"
                checkable: true
                checked: cmdBar.previewPanelVisible
                onTriggered: cmdBar.previewPanelToggled()
            }
        }

        MenuSeparator {}
        MenuItem {
            text: "Eliminar"
            enabled: cmdBar.hasSelection
            onTriggered: cmdBar.deleteRequested()
        }
        MenuItem {
            text: "Cambiar nombre"
            enabled: cmdBar.hasSelection
            onTriggered: cmdBar.renameRequested()
        }
        MenuSeparator {}
        MenuItem {
            text: "Propiedades"
            enabled: false
        }
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
            onClicked: organizarMenu.open()
        }

        // ── Separator ──
        CmdBarSeparator {}

        // ── Context buttons ──
        CmdBarButton {
            text: "Incluir en biblioteca ▾"
            visible: !fileSystemBackend.selectedFileInfo.isDir ||
                     fileSystemBackend.selectedCount === 0
        }

        CmdBarButton {
            text: "Compartir con ▾"
        }

        CmdBarSeparator {}

        CmdBarButton {
            text: "Grabar"
        }

        CmdBarButton {
            text: "Nueva carpeta"
            onClicked: cmdBar.newFolderRequested()
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // ── Right side ──
        CmdBarSeparator {}

        // Views menu button
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
                MenuItem { text: "Iconos medianos"; checkable: true; checked: true }
                MenuItem { text: "Iconos pequeños" }
                MenuSeparator {}
                MenuItem { text: "Lista" }
                MenuItem { text: "Detalles" }
                MenuItem { text: "Mosaicos" }
            }
        }

        // Preview pane toggle
        Rectangle {
            width: 24
            height: parent.height - 4
            radius: 2
            color: cmdBar.previewPanelVisible
                   ? Win7Theme.cmdBarBtnPressed
                   : previewBtnMa.containsMouse ? Win7Theme.cmdBarBtnHover : "transparent"
            border.color: cmdBar.previewPanelVisible ? Win7Theme.selectionBorder : "transparent"
            border.width: 1

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
                onClicked: cmdBar.previewPanelToggled()
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
