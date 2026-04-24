import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "styles"

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

    // ── Error notification ──
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
            anchors.leftMargin: 16
            anchors.rightMargin: 16
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

    // ── Main Layout ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ═══ Navigation Bar (Back/Forward + Address Bar + Search) ═══
        NavigationBar {
            id: navigationBar
            Layout.fillWidth: true
            Layout.preferredHeight: Win7Theme.navBarHeight + 6
        }

        // ═══ Command Bar ═══
        CommandBar {
            id: commandBar
            Layout.fillWidth: true
            Layout.preferredHeight: Win7Theme.cmdBarHeight
            onNewFolderRequested: contentArea.openNewFolderDialog()
        }

        // ═══ Separator line ═══
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Win7Theme.cmdBarBorderBottom
        }

        // ═══ Main Content Area (Nav Panel + Content + Preview) ═══
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Navigation Panel (Left Sidebar) ──
                NavigationPanel {
                    id: navPanel
                    Layout.preferredWidth: Win7Theme.navPanelDefaultWidth
                    Layout.fillHeight: true
                }

                // ── Splitter ──
                Rectangle {
                    Layout.preferredWidth: Win7Theme.splitterWidth
                    Layout.fillHeight: true
                    color: Win7Theme.splitterColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SplitHCursor
                        property int startX: 0
                        property int startWidth: 0

                        onPressed: (mouse) => {
                            startX = mouse.x
                            startWidth = navPanel.Layout.preferredWidth
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                let newWidth = startWidth + (mouse.x - startX)
                                navPanel.Layout.preferredWidth =
                                    Math.max(150, Math.min(400, newWidth))
                            }
                        }
                    }
                }

                // ── Content Area + Details Panel ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Content Area
                    ContentArea {
                        id: contentArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        searchQuery: navigationBar.searchText
                    }

                    // Details Panel separator
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Win7Theme.detailsPanelBorder
                    }

                    // Details Panel
                    DetailsPanel {
                        id: detailsPanel
                        Layout.fillWidth: true
                        Layout.preferredHeight: Win7Theme.detailsPanelHeight
                    }
                }
            }
        }

        // ═══ Status Bar ═══
        StatusBar {
            id: statusBar
            Layout.fillWidth: true
            Layout.preferredHeight: Win7Theme.statusBarHeight
        }
    }
}
