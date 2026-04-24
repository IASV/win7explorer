import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "styles/Win7Theme.js" as Win7Theme

ApplicationWindow {
    id: root
    width: 900
    height: 600
    minimumWidth: 640
    minimumHeight: 400
    visible: true
    title: {
        let segments = fileSystemBackend.pathSegments
        if (segments.length > 0)
            return segments[segments.length - 1].name
        return "Explorador"
    }
    color: Win7Theme.windowBackground

    property bool showNavPanel: true
    property bool showDetailsPanel: true
    property bool showPreviewPanel: false
    property int navPanelWidth: Win7Theme.navPanelDefaultWidth
    property int previewPanelWidth: 280

    Connections {
        target: fileSystemBackend
        function onErrorOccurred(message) {
            errorBar.message = message
            errorBar.visible = true
            errorTimer.restart()
        }
    }

    Rectangle {
        id: errorBar
        property string message: ""
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Win7Theme.statusBarHeight + 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(errorText.implicitWidth + 32, root.width - 40)
        height: 34
        radius: 4
        color: "#C0392B"
        visible: false
        z: 100

        Text {
            id: errorText
            anchors.centerIn: parent
            text: errorBar.message
            color: "white"
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeNormal + 1
            elide: Text.ElideRight
        }

        MouseArea { anchors.fill: parent; onClicked: errorBar.visible = false }

        Timer {
            id: errorTimer
            interval: 4000
            onTriggered: errorBar.visible = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        NavigationBar {
            id: navigationBar
            Layout.fillWidth: true
            Layout.preferredHeight: Win7Theme.navBarHeight + 6
        }

        CommandBar {
            id: commandBar
            Layout.fillWidth: true
            Layout.preferredHeight: Win7Theme.cmdBarHeight
            hasClipboard: contentArea.hasClipboard
            navPanelVisible: root.showNavPanel
            detailsPanelVisible: root.showDetailsPanel
            previewPanelVisible: root.showPreviewPanel

            onNewFolderRequested:    contentArea.openNewFolderDialog()
            onNavPanelToggled:       root.showNavPanel = !root.showNavPanel
            onDetailsPanelToggled:   root.showDetailsPanel = !root.showDetailsPanel
            onPreviewPanelToggled:   root.showPreviewPanel = !root.showPreviewPanel
            onCutRequested: {
                let p = fileSystemBackend.selectedFileInfo.path
                if (p) { contentArea.cbPath = p; contentArea.cbMode = "cut" }
            }
            onCopyRequested: {
                let p = fileSystemBackend.selectedFileInfo.path
                if (p) { contentArea.cbPath = p; contentArea.cbMode = "copy" }
            }
            onPasteRequested:   contentArea.pasteItem()
            onDeleteRequested: {
                let p = fileSystemBackend.selectedFileInfo.path
                if (p) contentArea.openDeleteDialog(p)
            }
            onRenameRequested: {
                let info = fileSystemBackend.selectedFileInfo
                if (info.path) contentArea.openRenameDialog(info.path, info.name)
            }
            onSelectAllRequested: contentArea.selectAll()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Win7Theme.cmdBarBorderBottom
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                NavigationPanel {
                    id: navPanel
                    Layout.preferredWidth: root.showNavPanel ? root.navPanelWidth : 0
                    Layout.maximumWidth: root.showNavPanel ? 400 : 0
                    Layout.minimumWidth: 0
                    Layout.fillHeight: true
                    clip: true
                }

                Rectangle {
                    Layout.preferredWidth: root.showNavPanel ? Win7Theme.splitterWidth : 0
                    Layout.maximumWidth: root.showNavPanel ? Win7Theme.splitterWidth : 0
                    Layout.fillHeight: true
                    color: Win7Theme.splitterColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SplitHCursor
                        property int startX: 0
                        property int startWidth: 0
                        onPressed: (mouse) => { startX = mouse.x; startWidth = root.navPanelWidth }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                root.navPanelWidth = Math.max(150, Math.min(400, startWidth + (mouse.x - startX)))
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    ContentArea {
                        id: contentArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        searchQuery: navigationBar.searchText
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.showDetailsPanel ? 1 : 0
                        Layout.maximumHeight: root.showDetailsPanel ? 1 : 0
                        color: Win7Theme.detailsPanelBorder
                    }

                    DetailsPanel {
                        id: detailsPanel
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.showDetailsPanel ? Win7Theme.detailsPanelHeight : 0
                        Layout.maximumHeight: root.showDetailsPanel ? Win7Theme.detailsPanelHeight : 0
                        clip: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.showPreviewPanel ? Win7Theme.splitterWidth : 0
                    Layout.maximumWidth: root.showPreviewPanel ? Win7Theme.splitterWidth : 0
                    Layout.fillHeight: true
                    color: Win7Theme.splitterColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SplitHCursor
                        property int startX: 0
                        property int startWidth: 0
                        onPressed: (mouse) => { startX = mouse.x; startWidth = root.previewPanelWidth }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                root.previewPanelWidth = Math.max(180, Math.min(500, startWidth - (mouse.x - startX)))
                        }
                    }
                }

                PreviewPanel {
                    id: previewPanel
                    Layout.preferredWidth: root.showPreviewPanel ? root.previewPanelWidth : 0
                    Layout.maximumWidth: root.showPreviewPanel ? 500 : 0
                    Layout.minimumWidth: 0
                    Layout.fillHeight: true
                    clip: true
                }
            }
        }

        StatusBar {
            id: statusBar
            Layout.fillWidth: true
            Layout.preferredHeight: Win7Theme.statusBarHeight
        }
    }
}
