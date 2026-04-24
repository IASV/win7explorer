import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles/Win7Theme.js" as Win7Theme

// ═══════════════════════════════════════════════════
// Navigation Panel: Left sidebar tree view
// Sections: Favoritos, Bibliotecas, Equipo (dynamic tree), Red
// ═══════════════════════════════════════════════════
Rectangle {
    id: navPanel
    color: Win7Theme.navPanelBg

    // Right border
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Win7Theme.navPanelBorder
    }

    ScrollView {
        anchors.fill: parent
        anchors.rightMargin: 1
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        background: null

        Flickable {
            contentWidth: width
            contentHeight: treeLayout.implicitHeight + 10

            ColumnLayout {
                id: treeLayout
                width: parent.width
                spacing: 0

                // ════════════════════════
                // ★ FAVORITOS
                // ════════════════════════
                NavSection {
                    title: "Favoritos"
                    icon: "★"
                    iconColor: "#E8B800"
                    expanded: true

                    model: ListModel {
                        ListElement { name: "Descargas"; icon: "image://fileicons/folder-download" }
                        ListElement { name: "Escritorio"; icon: "image://fileicons/user-desktop" }
                        ListElement { name: "Sitios recientes"; icon: "image://fileicons/document-open-recent" }
                    }

                    onItemClicked: function(itemName) {
                        switch (itemName) {
                            case "Descargas":
                                fileSystemBackend.navigateTo(fileSystemBackend.downloadsPath())
                                break
                            case "Escritorio":
                                fileSystemBackend.navigateTo(fileSystemBackend.desktopPath())
                                break
                        }
                    }
                }

                // ════════════════════════
                // 📚 BIBLIOTECAS
                // ════════════════════════
                NavSection {
                    title: "Bibliotecas"
                    icon: "📚"
                    iconColor: "#4A90D9"
                    expanded: true

                    model: ListModel {
                        ListElement { name: "Documentos"; icon: "image://fileicons/folder-documents" }
                        ListElement { name: "Imágenes"; icon: "image://fileicons/folder-pictures" }
                        ListElement { name: "Música"; icon: "image://fileicons/folder-music" }
                        ListElement { name: "Vídeos"; icon: "image://fileicons/folder-video" }
                    }

                    onItemClicked: function(itemName) {
                        switch (itemName) {
                            case "Documentos":
                                fileSystemBackend.navigateTo(fileSystemBackend.documentsPath())
                                break
                            case "Imágenes":
                                fileSystemBackend.navigateTo(fileSystemBackend.picturesPath())
                                break
                            case "Música":
                                fileSystemBackend.navigateTo(fileSystemBackend.musicPath())
                                break
                            case "Vídeos":
                                fileSystemBackend.navigateTo(fileSystemBackend.videosPath())
                                break
                        }
                    }
                }

                // ════════════════════════
                // 💻 EQUIPO — expandable folder tree
                // ════════════════════════
                ColumnLayout {
                    id: equipoSection
                    Layout.fillWidth: true
                    spacing: 0
                    property bool sectionExpanded: true

                    // Section header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        color: equipoHdrMa.containsMouse ? Win7Theme.navPanelItemHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            spacing: 4

                            Text {
                                text: equipoSection.sectionExpanded ? "▾" : "▸"
                                font.pixelSize: 8
                                color: Win7Theme.navPanelExpandArrow
                                Layout.preferredWidth: 10
                            }
                            Text { text: "💻"; font.pixelSize: 13 }
                            Text {
                                text: "Equipo"
                                font.family: Win7Theme.fontFamily
                                font.pixelSize: Win7Theme.fontSizeNormal + 2
                                font.bold: true
                                color: Win7Theme.navPanelItemText
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: equipoHdrMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: equipoSection.sectionExpanded = !equipoSection.sectionExpanded
                        }
                    }

                    // Dynamic folder tree rooted at "/"
                    FolderTreeNode {
                        Layout.fillWidth: true
                        Layout.preferredHeight: equipoSection.sectionExpanded ? implicitHeight : 0
                        visible: equipoSection.sectionExpanded
                        nodePath: "/"
                        nodeName: "Disco local (/)"
                        depth: 0
                        nodeHasChildren: true
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: Win7Theme.navPanelBorder
                    }
                }

                // ════════════════════════
                // 🌐 RED
                // ════════════════════════
                NavSection {
                    title: "Red"
                    icon: "🌐"
                    iconColor: "#4A90D9"
                    expanded: false
                    model: ListModel {}
                }

                Item { Layout.preferredHeight: 20 }
            }
        }
    }

    // ═══ Navigation Section Component (flat list style) ═══
    component NavSection: ColumnLayout {
        id: section
        Layout.fillWidth: true
        spacing: 0

        property string title: ""
        property string icon: ""
        property color iconColor: "#000000"
        property bool expanded: true
        property alias model: sectionRepeater.model
        signal itemClicked(string itemName)

        // Section header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: sectionHeaderMa.containsMouse ? Win7Theme.navPanelItemHover
                                                  : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                spacing: 4

                Text {
                    text: section.expanded ? "▾" : "▸"
                    font.pixelSize: 8
                    color: Win7Theme.navPanelExpandArrow
                    Layout.preferredWidth: 10
                }

                Text {
                    text: section.icon
                    font.pixelSize: 13
                }

                Text {
                    text: section.title
                    font.family: Win7Theme.fontFamily
                    font.pixelSize: Win7Theme.fontSizeNormal + 2
                    font.bold: true
                    color: Win7Theme.navPanelItemText
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: sectionHeaderMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: section.expanded = !section.expanded
            }
        }

        // Section items
        Repeater {
            id: sectionRepeater

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                visible: section.expanded
                color: itemMa.containsMouse ? Win7Theme.navPanelItemHover : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    spacing: 4

                    Image {
                        width: 16; height: 16
                        sourceSize: Qt.size(16, 16)
                        source: model.icon
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: model.name
                        font.family: Win7Theme.fontFamily
                        font.pixelSize: Win7Theme.fontSizeNormal + 2
                        color: Win7Theme.navPanelItemText
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: section.itemClicked(model.name)
                }
            }
        }

        // Bottom separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            color: Win7Theme.navPanelBorder
        }
    }
}
