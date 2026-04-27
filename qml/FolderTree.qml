import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: folderTree
    property var    pal
    property string currentPath: ""
    property var    favorites: [
        { name: "Escritorio", path: fsBackend.desktopPath(),   icon: "folder-closed" },
        { name: "Descargas",  path: fsBackend.downloadsPath(), icon: "folder-blue" }
    ]

    signal folderActivated(string path)

    onFavoritesChanged: loadTree()

    ListView {
        id: treeView
        anchors.fill: parent
        clip: true
        model: treeModel
        delegate: treeDelegate
    }

    ListModel { id: treeModel }

    Component {
        id: treeDelegate
        Rectangle {
            id: row
            width: treeView.width
            height: 22

            readonly property string itemType:        type
            readonly property string itemName:        name
            readonly property string itemPath:        path
            readonly property int    itemLevel:       level
            readonly property string itemIcon:        icon
            readonly property bool   itemHasChildren: hasChildren
            readonly property bool   itemExpanded:    expanded
            readonly property int    itemIndex:       index
            readonly property string itemSection:     sectionType

            // Indentation x for toggle area
            readonly property int indentX: itemLevel * 14 + (itemType === "header" ? 6 : 18)

            color: {
                if (itemType === "header" && itemPath === "") return "transparent"
                if (currentPath === itemPath && itemPath !== "") return pal.sbCurrent
                return rowMouse.containsMouse ? pal.sbHover : "transparent"
            }

            // Left selection bar
            Rectangle {
                visible: itemPath !== "" && currentPath === itemPath
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 2; color: pal.selectionBorder
            }

            // Row content
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: row.indentX
                anchors.rightMargin: 4
                spacing: 4

                // Triangle (visual only — click is handled by toggleMa below)
                Item {
                    Layout.preferredWidth: 12; Layout.preferredHeight: 12
                    Layout.alignment: Qt.AlignVCenter
                    opacity: itemHasChildren ? 1 : 0

                    Canvas {
                        anchors.fill: parent
                        property color fg: pal ? pal.muted : "#888"
                        property bool expanded: itemExpanded
                        onFgChanged: requestPaint()
                        onExpandedChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, 12, 12)
                            if (expanded) {
                                ctx.fillStyle = "#555"
                                ctx.beginPath()
                                ctx.moveTo(2, 3); ctx.lineTo(10, 3); ctx.lineTo(6, 9)
                                ctx.closePath(); ctx.fill()
                            } else {
                                ctx.strokeStyle = fg
                                ctx.lineWidth = 1.2
                                ctx.beginPath()
                                ctx.moveTo(3, 2); ctx.lineTo(9, 6); ctx.lineTo(3, 10)
                                ctx.closePath(); ctx.stroke()
                            }
                        }
                    }
                }

                Image {
                    visible: itemType !== "header" || itemPath !== ""
                    source: (itemPath !== "" && currentPath === itemPath &&
                             (itemIcon === "folder-closed" || itemIcon === "folder-blue"))
                            ? "qrc:/icons/folder-semi.png"
                            : "qrc:/icons/" + itemIcon + ".png"
                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                }
                Item {
                    visible: itemType === "header" && itemPath === ""
                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                }

                Label {
                    text: itemName
                    color: currentPath === itemPath && itemPath !== "" ? pal.selText
                         : itemType === "header" ? pal.muted
                         : pal.sbText
                    font.pixelSize: 12
                    font.bold: itemType === "header"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            // ── Row hover + navigate (lower z-order — declared first) ──────
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (itemPath) folderTree.folderActivated(itemPath)
                }
            }

            // ── Toggle click (higher z-order — declared AFTER rowMouse) ───
            // Covers exactly the triangle area so it intercepts clicks before rowMouse.
            MouseArea {
                id: toggleMa
                x: row.indentX - 2
                y: 0
                width: 20
                height: parent.height
                visible: itemHasChildren
                // No hoverEnabled — rowMouse handles hover color
                onClicked: function(mouse) {
                    mouse.accepted = true
                    toggleNode(row.itemPath, row.itemIndex, row.itemSection)
                }
            }
        }
    }

    // ── Toggle collapse / expand ───────────────────────────────────────────
    function toggleNode(path, idx, sectionType) {
        if (idx < 0 || idx >= treeModel.count) return
        var item = treeModel.get(idx)
        if (!item) return

        if (item.expanded) {
            // Collapse: remove all direct and indirect descendants
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
            // Expand: insert children
            var childLevel = item.level + 1
            var sType = sectionType || ""

            if (sType === "favorites") {
                var favs = folderTree.favorites
                for (var a = favs.length - 1; a >= 0; a--)
                    treeModel.insert(idx + 1, {
                        name: favs[a].name, type: "special", level: childLevel,
                        icon: favs[a].icon || "folder-closed", path: favs[a].path,
                        hasChildren: false, expanded: false, sectionType: ""
                    })
            } else if (sType === "libraries") {
                var libs = fsBackend.getLibraries()
                for (var b = libs.length - 1; b >= 0; b--)
                    treeModel.insert(idx + 1, {
                        name: libs[b].name, type: "special", level: childLevel,
                        icon: libs[b].icon, path: libs[b].path,
                        hasChildren: false, expanded: false, sectionType: ""
                    })
            } else if (sType === "equipo") {
                var drives = fsBackend.getStorageDevices()
                for (var c = drives.length - 1; c >= 0; c--)
                    treeModel.insert(idx + 1, {
                        name: drives[c].displayName, type: "special", level: childLevel,
                        icon: "drive-" + drives[c].kind, path: drives[c].path,
                        hasChildren: drives[c].path !== "", expanded: false, sectionType: ""
                    })
            } else {
                // Real filesystem folder
                var subs = fsBackend.getSubdirectories(path)
                for (var d = subs.length - 1; d >= 0; d--)
                    treeModel.insert(idx + 1, {
                        name: subs[d].name, type: "folder", level: childLevel,
                        icon: "folder-closed", path: subs[d].path,
                        hasChildren: subs[d].hasChildren, expanded: false, sectionType: ""
                    })
            }
            treeModel.setProperty(idx, "expanded", true)
        }
    }

    // ── Build initial tree ─────────────────────────────────────────────────
    function loadTree() {
        treeModel.clear()

        // Favoritos
        treeModel.append({
            name: "Favoritos", type: "header", level: 0, icon: "folder-closed",
            path: "", hasChildren: favorites.length > 0, expanded: true, sectionType: "favorites"
        })
        for (var i = 0; i < favorites.length; i++)
            treeModel.append({
                name: favorites[i].name, type: "special", level: 1,
                icon: favorites[i].icon || "folder-closed",
                path: favorites[i].path, hasChildren: false, expanded: false, sectionType: ""
            })

        // Bibliotecas
        var libs = fsBackend.getLibraries()
        treeModel.append({
            name: "Bibliotecas", type: "header", level: 0, icon: "document",
            path: "", hasChildren: libs.length > 0, expanded: true, sectionType: "libraries"
        })
        for (var j = 0; j < libs.length; j++)
            treeModel.append({
                name: libs[j].name, type: "special", level: 1, icon: libs[j].icon,
                path: libs[j].path, hasChildren: false, expanded: false, sectionType: ""
            })

        // Equipo
        var drives = fsBackend.getStorageDevices()
        treeModel.append({
            name: "Equipo", type: "header", level: 0, icon: "window",
            path: "computer", hasChildren: drives.length > 0, expanded: true, sectionType: "equipo"
        })
        for (var k = 0; k < drives.length; k++)
            treeModel.append({
                name: drives[k].displayName, type: "special", level: 1,
                icon: "drive-" + drives[k].kind,
                path: drives[k].path, hasChildren: drives[k].path !== "",
                expanded: false, sectionType: ""
            })

        // Red
        treeModel.append({
            name: "Red", type: "header", level: 0, icon: "network",
            path: "network", hasChildren: false, expanded: false, sectionType: ""
        })

        // Panel de control
        treeModel.append({
            name: "Panel de control", type: "header", level: 0, icon: "control-panel",
            path: "control-panel", hasChildren: false, expanded: false, sectionType: ""
        })
        // Papelera de reciclaje
        treeModel.append({
            name: "Papelera de reciclaje", type: "special", level: 0, icon: "folder-empty",
            path: "trash", hasChildren: false, expanded: false, sectionType: ""
        })
    }

    Component.onCompleted: loadTree()
}
