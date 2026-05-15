import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: folderTree
    property var    pal
    property string currentPath: ""
    property var    favorites: [
        { name: (I18n.lang, I18n.t("Escritorio")), path: FsBackend.desktopPath(),   icon: "folder-closed" },
        { name: (I18n.lang, I18n.t("Descargas")),  path: FsBackend.downloadsPath(), icon: "folder-blue" }
    ]

    signal folderActivated(string path)

    onFavoritesChanged: loadTree()

    ListView {
        id: treeView
        anchors.fill: parent
        clip: true
        model: treeModel
        delegate: treeDelegate
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
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

            // Indentation x for toggle area — level-0 items always flush at 6
            readonly property int indentX: itemLevel * 14 + (itemLevel === 0 ? 6 : 18)

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
                    source: {
                        if (itemPath !== "" && currentPath === itemPath &&
                            (itemIcon === "folder-closed" || itemIcon === "folder-blue"))
                            return "qrc:/icons/folder-semi.png"
                        return "image://fileicons/" + itemIcon
                    }
                    sourceSize: Qt.size(16, 16)
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
                         : pal.sbText
                    font.pixelSize: 12
                    font.bold: false
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
                var libs = FsBackend.getLibraries()
                for (var b = libs.length - 1; b >= 0; b--)
                    treeModel.insert(idx + 1, {
                        name: libs[b].name, type: "special", level: childLevel,
                        icon: libs[b].icon, path: libs[b].path,
                        hasChildren: false, expanded: false, sectionType: ""
                    })
            } else if (sType === "equipo") {
                var drives = FsBackend.getStorageDevices()
                for (var c = drives.length - 1; c >= 0; c--)
                    treeModel.insert(idx + 1, {
                        name: drives[c].displayName, type: "special", level: childLevel,
                        icon: "drive-" + drives[c].kind, path: drives[c].path,
                        hasChildren: drives[c].path !== "", expanded: false, sectionType: ""
                    })
            } else if (sType === "network") {
                var nets = FsBackend.getNetworkDevices()
                treeModel.insert(idx + 1, {
                    name: (I18n.lang, I18n.t("Conectar a servidor…")), type: "special", level: childLevel,
                    icon: "network-connect", path: "network:connect",
                    hasChildren: false, expanded: false, sectionType: ""
                })
                for (var e = nets.length - 1; e >= 0; e--)
                    treeModel.insert(idx + 1, {
                        name: nets[e].displayName, type: "special", level: childLevel,
                        icon: "network-workgroup", path: nets[e].path,
                        hasChildren: false, expanded: false, sectionType: ""
                    })
            } else {
                // Real filesystem folder
                var subs = FsBackend.getSubdirectories(path)
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
            name: (I18n.lang, I18n.t("Favoritos")), type: "header", level: 0, icon: "folder-closed",
            path: "", hasChildren: favorites.length > 0, expanded: true, sectionType: "favorites"
        })
        for (var i = 0; i < favorites.length; i++)
            treeModel.append({
                name: favorites[i].name, type: "special", level: 1,
                icon: favorites[i].icon || "folder-closed",
                path: favorites[i].path, hasChildren: false, expanded: false, sectionType: ""
            })

        // Bibliotecas
        var libs = FsBackend.getLibraries()
        treeModel.append({
            name: (I18n.lang, I18n.t("Bibliotecas")), type: "header", level: 0, icon: "libraries",
            path: "libraries", hasChildren: libs.length > 0, expanded: true, sectionType: "libraries"
        })
        for (var j = 0; j < libs.length; j++)
            treeModel.append({
                name: libs[j].name, type: "special", level: 1, icon: libs[j].icon,
                path: libs[j].path, hasChildren: false, expanded: false, sectionType: ""
            })

        // Equipo
        var drives = FsBackend.getStorageDevices()
        treeModel.append({
            name: (I18n.lang, I18n.t("Equipo")), type: "header", level: 0, icon: "computer",
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
            name: (I18n.lang, I18n.t("Red")), type: "header", level: 0, icon: "network-workgroup",
            path: "network", hasChildren: true, expanded: false, sectionType: "network"
        })

        // Papelera de reciclaje
        treeModel.append({
            name: (I18n.lang, I18n.t("Papelera de reciclaje")), type: "special", level: 0, icon: "user-trash",
            path: "trash", hasChildren: false, expanded: false, sectionType: ""
        })
    }

    Connections {
        target: FsBackend
        function onDevicesChanged() { refreshDevices() }
    }

    // Refresh only the Equipo / Red sections without touching Favorites or Libraries.
    function refreshDevices() {
        // Collect device sections in reverse order so index arithmetic stays valid
        // after we start removing children (modifying from bottom up).
        var toRefresh = []
        for (var i = 0; i < treeModel.count; i++) {
            var sType = treeModel.get(i).sectionType || ""
            if (sType === "equipo" || sType === "network")
                toRefresh.push(i)
        }
        for (var j = toRefresh.length - 1; j >= 0; j--) {
            var idx  = toRefresh[j]
            var item = treeModel.get(idx)
            if (!item.expanded) continue

            // Collapse: remove all children of this header
            var parentLevel = item.level
            var start = idx + 1
            var cnt = 0
            while (start + cnt < treeModel.count &&
                   treeModel.get(start + cnt).level > parentLevel)
                cnt++
            for (var r = 0; r < cnt; r++) treeModel.remove(start)
            treeModel.setProperty(idx, "expanded", false)

            // Re-expand with fresh data
            toggleNode(treeModel.get(idx).path, idx, treeModel.get(idx).sectionType)
        }
    }

    // Defer initial tree build so the window renders its first frame first.
    Component.onCompleted: Qt.callLater(loadTree)
}
