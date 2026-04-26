import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: folderTree
    property var pal
    property string currentPath: ""

    signal folderActivated(string path)

    ListView {
        id: treeView
        anchors.fill: parent
        clip: true
        model: treeModel
        delegate: treeDelegate
    }

    ListModel {
        id: treeModel
    }

    Component {
        id: treeDelegate
        Rectangle {
            id: row
            width: treeView.width
            height: 22

            // Capture ListModel roles into properties so nested items can access them
            readonly property string itemType:        type
            readonly property string itemName:        name
            readonly property string itemPath:        path
            readonly property int    itemLevel:       level
            readonly property string itemIcon:        icon
            readonly property bool   itemHasChildren: hasChildren
            readonly property bool   itemExpanded:    expanded
            readonly property int    itemIndex:       index

            color: {
                if (itemType === "header") return "transparent"
                return (currentPath === itemPath)
                       ? pal.sbCurrent
                       : (rowMouse.containsMouse ? pal.sbHover : "transparent")
            }

            // Left selection indicator
            Rectangle {
                visible: itemType !== "header" && currentPath === itemPath
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: pal.selectionBorder
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: itemLevel * 14 + (itemType === "header" ? 6 : 18)
                anchors.rightMargin: 4
                spacing: 4

                // Animated chevron for expandable folders
                Item {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    opacity: (itemType === "folder" || itemType === "special") && itemHasChildren ? 1 : 0
                    rotation: itemExpanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 120 } }

                    Canvas {
                        anchors.fill: parent
                        property color fg: pal ? pal.muted : "#888"
                        onFgChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, 12, 12)
                            ctx.strokeStyle = fg
                            ctx.lineWidth = 1.4
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(3, 1.5)
                            ctx.lineTo(9, 6)
                            ctx.lineTo(3, 10.5)
                            ctx.stroke()
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            mouse.accepted = true
                            toggleNode(row.itemPath, row.itemIndex)
                        }
                    }
                }

                Image {
                    visible: itemType !== "header"
                    source: "qrc:/icons/" + itemIcon + ".png"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    text: itemName
                    color: itemType === "header"   ? pal.muted
                         : currentPath === itemPath ? pal.selText
                         :                            pal.sbText
                    font.pixelSize: 12
                    font.bold: itemType === "header"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (itemType !== "header" && itemPath) {
                        folderTree.folderActivated(itemPath)
                    }
                }
            }
        }
    }

    // Expand or collapse a node at the given model index
    function toggleNode(path, idx) {
        if (idx < 0 || idx >= treeModel.count) return
        var item = treeModel.get(idx)
        if (!item) return

        if (item.expanded) {
            // Collapse: remove all descendants (everything with level > item.level
            // up until the next item at same or lower level)
            var parentLevel = item.level
            var start = idx + 1
            var count = 0
            while (start + count < treeModel.count) {
                if (treeModel.get(start + count).level <= parentLevel) break
                count++
            }
            for (var r = 0; r < count; r++)
                treeModel.remove(start)
            treeModel.setProperty(idx, "expanded", false)
        } else {
            // Expand: insert immediate children after this item
            var childLevel = item.level + 1
            var subs = fsBackend.getSubdirectories(path)
            for (var j = subs.length - 1; j >= 0; j--) {
                treeModel.insert(idx + 1, {
                    name:        subs[j].name,
                    type:        "folder",
                    level:       childLevel,
                    icon:        "folder-closed",
                    path:        subs[j].path,
                    hasChildren: subs[j].hasChildren,
                    expanded:    false
                })
            }
            treeModel.setProperty(idx, "expanded", true)
        }
    }

    function loadTree() {
        treeModel.clear()

        // Favorites
        treeModel.append({ name: "Favoritos",     type: "header",  level: 0, icon: "folder-closed", path: "",                              hasChildren: false, expanded: false })
        treeModel.append({ name: "Escritorio",    type: "special", level: 1, icon: "folder-closed", path: fsBackend.desktopPath(),         hasChildren: false, expanded: false })
        treeModel.append({ name: "Descargas",     type: "special", level: 1, icon: "folder-blue",   path: fsBackend.downloadsPath(),       hasChildren: false, expanded: false })
        treeModel.append({ name: "Sitios recientes", type: "special", level: 1, icon: "folder-search", path: "",                          hasChildren: false, expanded: false })

        // Libraries
        treeModel.append({ name: "Bibliotecas",   type: "header",  level: 0, icon: "document",      path: "",                              hasChildren: false, expanded: false })
        var libs = fsBackend.getLibraries()
        for (var i = 0; i < libs.length; i++)
            treeModel.append({ name: libs[i].name, type: "special", level: 1, icon: libs[i].icon, path: libs[i].path, hasChildren: false, expanded: false })

        // Computer / drives
        treeModel.append({ name: "Equipo",        type: "header",  level: 0, icon: "window",        path: "",                              hasChildren: false, expanded: false })
        var drives = fsBackend.getStorageDevices()
        for (var j = 0; j < drives.length; j++)
            treeModel.append({ name: drives[j].label, type: "special", level: 1, icon: "drive-" + drives[j].kind, path: drives[j].path, hasChildren: drives[j].path !== "", expanded: false })

        // Home folder tree
        treeModel.append({ name: "Inicio",        type: "header",  level: 0, icon: "folder-closed", path: "",                              hasChildren: false, expanded: false })
        var home = fsBackend.homePath()
        treeModel.append({ name: "Inicio",        type: "folder",  level: 1, icon: "folder-closed", path: home,                            hasChildren: true,  expanded: false })
    }

    Component.onCompleted: loadTree()
}
