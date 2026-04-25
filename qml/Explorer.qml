// Explorer.qml — Qt 6 QML · Win7 File Explorer replica
// Visually matches the HTML prototype (html/Explorador.html)

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1180
    height: 760
    visible: true
    title: currentNode ? currentNode.name : "Explorador"
    flags: Qt.Window

// ---------- Modelo ----------
FileSystem { id: fs }

// ---------- Estado ----------
property var historyStack: [["libraries"]]
property int historyIndex: 0
property string currentId: historyStack[historyIndex][historyStack[historyIndex].length - 1]
property var currentNode: fs.findNode(currentId)
property var pathToCurrent: fs.pathTo(currentId) || []

property string viewMode: "large"
property var selectedIds: ({})
property int selectedCount: 0
property string searchQuery: ""
property string sortBy: "name"
property string sortDir: "asc"

property string themeName: "glass"
property string density: "comfortable"
property bool showSidebar: true
property bool showPreview: true

// Nuevas propiedades para vistas especiales
property var storageDevices: []
property var libraries: []
property string currentSpecialView: "" // "computer", "libraries", "", etc.

// Cargar datos del sistema
Component.onCompleted: {
    storageDevices = fsBackend.getStorageDevices()
    libraries = fsBackend.getLibraries()
}

    // ---------- Paletas (con stops de gradiente) ----------
    readonly property var palettes: ({
        glass: {
            bg1: "#e8f0fa", bg2: "#c8d9ee",
            panel: "#f6f9fc", border: "#c0ccd9", borderSoft: "#e2e8f0",
            sidebar: "#eef4fb", sbText: "#26334a",
            sbHover: "#d4e4f5", sbCurrent: "#b8d4f0",
            tbar1: "#fafcff", tbar2: "#e7eef7",
            content: "#ffffff", text: "#1e2836", muted: "#6a7788",
            selection: "#b8d4f0", selectionBorder: "#5a9bd4", selText: "#0c2a4a",
            accent: "#3f7cb8", accentSoft: "#d4e6f7",
            stat1: "#f1f5fa", stat2: "#e3ebf4"
        },
        flat: {
            bg1: "#f5f7fa", bg2: "#f5f7fa",
            panel: "#ffffff", border: "#e2e8f0", borderSoft: "#eef2f6",
            sidebar: "#fafbfc", sbText: "#1e2836",
            sbHover: "#eef2f6", sbCurrent: "#e7f0fb",
            tbar1: "#ffffff", tbar2: "#ffffff",
            content: "#ffffff", text: "#1e2836", muted: "#6a7788",
            selection: "#e7f0fb", selectionBorder: "#86b4e2", selText: "#13243a",
            accent: "#3f7cb8", accentSoft: "#e7f0fb",
            stat1: "#fafbfc", stat2: "#fafbfc"
        },
        dark: {
            bg1: "#1a1f2b", bg2: "#0f131c",
            panel: "#1e242f", border: "#2d3441", borderSoft: "#262d3b",
            sidebar: "#1c222d", sbText: "#c8d0dd",
            sbHover: "#262d3b", sbCurrent: "#2d3e5e",
            tbar1: "#1e242f", tbar2: "#1e242f",
            content: "#161b24", text: "#d9e1ed", muted: "#8a94a6",
            selection: "#2d3e5e", selectionBorder: "#5a7eb8", selText: "#e8eef8",
            accent: "#6ba7e0", accentSoft: "#2d3e5e",
            stat1: "#1c222d", stat2: "#1c222d"
        },
        warm: {
            bg1: "#faf2e0", bg2: "#ebdec2",
            panel: "#fcf7eb", border: "#d4c6a4", borderSoft: "#e4d7b8",
            sidebar: "#f9f2e0", sbText: "#3d3220",
            sbHover: "#f1e7cd", sbCurrent: "#e8d8b0",
            tbar1: "#fbf5e8", tbar2: "#fbf5e8",
            content: "#fffaed", text: "#3d3220", muted: "#7d6b48",
            selection: "#f0d998", selectionBorder: "#b39040", selText: "#3d2a0a",
            accent: "#b37c1d", accentSoft: "#f5e4ba",
            stat1: "#f9f2e0", stat2: "#f9f2e0"
        },
        neon: {
            bg1: "#080d18", bg2: "#030509",
            panel: "#0a0f1a", border: "#1a2540", borderSoft: "#18203a",
            sidebar: "#0a0f1a", sbText: "#a0b4c8",
            sbHover: "#122038", sbCurrent: "#1a3358",
            tbar1: "#0a0f1a", tbar2: "#0a0f1a",
            content: "#05080f", text: "#c8e8f5", muted: "#6a8aa8",
            selection: "#132030", selectionBorder: "#7ee8d8", selText: "#7ee8d8",
            accent: "#7ee8d8", accentSoft: "#132030",
            stat1: "#080d18", stat2: "#080d18"
        }
    })
    readonly property var pal: palettes[themeName]
    readonly property real densityMul: density === "compact" ? 0.82 : 1

    // ---------- Derivados ----------
    readonly property var rawItems: {
        if (!currentNode) return []
        if (searchQuery.trim().length > 0) {
            var q = searchQuery.toLowerCase()
            return fs.flattenFiles(currentNode).filter(function(f){
                return f.name.toLowerCase().indexOf(q) >= 0
            })
        }
        return currentNode.children || []
    }
    readonly property var items: {
        var arr = rawItems.slice()
        arr.sort(function(a, b) {
            if (a.type !== b.type) {
                if (a.type === "folder" && b.type !== "folder") return -1
                if (b.type === "folder" && a.type !== "folder") return 1
            }
            var av, bv
            if (sortBy === "name") { av = a.name.toLowerCase(); bv = b.name.toLowerCase() }
            else if (sortBy === "modified") { av = a.modified || ""; bv = b.modified || "" }
            else if (sortBy === "type") { av = a.ext || ""; bv = b.ext || "" }
            else { av = parseSize(a.size); bv = parseSize(b.size) }
            if (av < bv) return sortDir === "asc" ? -1 : 1
            if (av > bv) return sortDir === "asc" ? 1 : -1
            return 0
        })
        return arr
    }

    function parseSize(s) {
        if (!s) return -1
        var m = String(s).match(/([\d.]+)\s*(KB|MB|GB|B)/i)
        if (!m) return 0
        var v = parseFloat(m[1]), u = m[2].toUpperCase()
        return v * (u === "GB" ? 1e9 : u === "MB" ? 1e6 : u === "KB" ? 1e3 : 1)
    }

    // ---------- Navegación ----------
    function navigate(id) {
        if (id === currentId) return
        var next = historyStack.slice(0, historyIndex + 1)
        next.push([id])
        historyStack = next
        historyIndex = next.length - 1
        selectedIds = ({}); selectedCount = 0; searchQuery = ""
        currentId = id
        currentNode = fs.findNode(id)
        pathToCurrent = fs.pathTo(id) || []
    }
    function goBack() {
        if (historyIndex > 0) {
            historyIndex--
            currentId = historyStack[historyIndex][historyStack[historyIndex].length - 1]
            currentNode = fs.findNode(currentId)
            pathToCurrent = fs.pathTo(currentId) || []
            selectedIds = ({}); selectedCount = 0; searchQuery = ""
        }
    }
    function goForward() {
        if (historyIndex < historyStack.length - 1) {
            historyIndex++
            currentId = historyStack[historyIndex][historyStack[historyIndex].length - 1]
            currentNode = fs.findNode(currentId)
            pathToCurrent = fs.pathTo(currentId) || []
            selectedIds = ({}); selectedCount = 0; searchQuery = ""
        }
    }
    function goUp() {
        if (pathToCurrent.length > 1) navigate(pathToCurrent[pathToCurrent.length - 2].id)
    }

    function toggleSelect(id, ctrl, shift) {
        var next = ctrl ? Object.assign({}, selectedIds) : {}
        if (ctrl) {
            if (next[id]) delete next[id]; else next[id] = true
        } else {
            next[id] = true
        }
        selectedIds = next
        selectedCount = Object.keys(next).length
    }
    function isSelected(id) { return selectedIds[id] === true }

    function doubleClickItem(item) {
        if (item.type === "folder" || item.type === "group" || item.type === "drive")
            navigate(item.id)
        else showToast("Abriendo \"" + item.name + "\"...")
    }

    function handleDelete() {
        if (selectedCount === 0) return
        fs.deleteItems(Object.keys(selectedIds))
        showToast("Eliminado" + (selectedCount > 1 ? "s" : "") + " " + selectedCount + " elemento(s)")
        selectedIds = ({}); selectedCount = 0
        currentNode = fs.findNode(currentId)
    }
    function handleNewFolder() {
        var id = fs.addFolder(currentId, "Nueva carpeta")
        currentNode = fs.findNode(currentId)
        if (id) { selectedIds = {}; selectedIds[id] = true; selectedCount = 1 }
        showToast("Carpeta creada")
    }
    function handleCopy() {
        if (selectedCount === 0) return
        showToast("Copiado al portapapeles")
    }
    function setSort(col) {
        if (sortBy === col) sortDir = sortDir === "asc" ? "desc" : "asc"
        else { sortBy = col; sortDir = "asc" }
    }

    // ---------- Toast ----------
    property string toastMsg: ""
    Timer { id: toastTimer; interval: 1800; onTriggered: toastMsg = "" }
    function showToast(m) { toastMsg = m; toastTimer.restart() }

    // ---------- Atajos ----------
    Shortcut { sequence: "Delete"; onActivated: handleDelete() }
    Shortcut { sequence: "Backspace"; onActivated: goUp() }
    Shortcut { sequence: "Alt+Left"; onActivated: goBack() }
    Shortcut { sequence: "Alt+Right"; onActivated: goForward() }
    Shortcut { sequence: "Alt+Up"; onActivated: goUp() }
    Shortcut { sequence: "Ctrl+A"; onActivated: {
        var all = {}; for (var i = 0; i < items.length; i++) all[items[i].id] = true
        selectedIds = all; selectedCount = items.length
    }}
    Shortcut { sequence: "F5"; onActivated: showToast("Actualizando...") }

    // ---------- Raíz visual ----------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: win.pal.bg1 }
            GradientStop { position: 1; color: win.pal.bg2 }
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        color: win.pal.panel
        border.color: win.pal.border

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ==================== ADDRESS BAR ====================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                border.color: win.pal.borderSoft
                gradient: Gradient {
                    GradientStop { position: 0; color: win.pal.tbar1 }
                    GradientStop { position: 1; color: win.pal.tbar2 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 6

                    // Nav arrows: back · forward · up
                    RowLayout {
                        spacing: 2
                        Repeater {
                            model: [
                                { pts: [[9,2],[4,7],[9,12]], clr: "accent",
                                  get enabled() { return win.historyIndex > 0 },
                                  action: function(){ win.goBack() } },
                                { pts: [[5,2],[10,7],[5,12]], clr: "accent",
                                  get enabled() { return win.historyIndex < win.historyStack.length - 1 },
                                  action: function(){ win.goForward() } },
                                { pts: [[2,9],[7,4],[12,9]], clr: "muted",
                                  get enabled() { return win.pathToCurrent.length > 1 },
                                  action: function(){ win.goUp() } }
                            ]
                            delegate: Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 13
                                color: navArea.containsMouse && modelData.enabled
                                       ? win.pal.accentSoft : "transparent"
                                border.color: navArea.containsMouse && modelData.enabled
                                              ? win.pal.border : "transparent"
                                opacity: modelData.enabled ? 1.0 : 0.35

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 14; height: 14
                                    property var pts: modelData.pts
                                    property color fg: modelData.clr === "accent"
                                        ? win.pal.accent : win.pal.muted
                                    onFgChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, 14, 14)
                                        ctx.strokeStyle = fg
                                        ctx.lineWidth = 1.8
                                        ctx.lineCap = "round"
                                        ctx.lineJoin = "round"
                                        ctx.beginPath()
                                        ctx.moveTo(pts[0][0], pts[0][1])
                                        ctx.lineTo(pts[1][0], pts[1][1])
                                        ctx.lineTo(pts[2][0], pts[2][1])
                                        ctx.stroke()
                                    }
                                }

                                MouseArea {
                                    id: navArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: modelData.enabled
                                    onClicked: modelData.action()
                                }
                            }
                        }
                    }

                    // Breadcrumb bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        color: win.pal.content
                        border.color: win.pal.borderSoft
                        radius: 3
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 0

                            Repeater {
                                model: win.pathToCurrent
                                delegate: RowLayout {
                                    spacing: 0

                                    // SVG separator chevron (›)
                                    Canvas {
                                        visible: index > 0
                                        Layout.preferredWidth: 8
                                        Layout.preferredHeight: 10
                                        property color fg: win.pal.muted
                                        onFgChanged: requestPaint()
                                        Component.onCompleted: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, 8, 10)
                                            ctx.strokeStyle = fg
                                            ctx.lineWidth = 1.4
                                            ctx.lineCap = "round"
                                            ctx.beginPath()
                                            ctx.moveTo(2, 1)
                                            ctx.lineTo(6, 5)
                                            ctx.lineTo(2, 9)
                                            ctx.stroke()
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: 20
                                        color: crumbHov.containsMouse ? win.pal.accentSoft : "transparent"
                                        radius: 2
                                        implicitWidth: crumbLbl.implicitWidth + 14

                                        Label {
                                            id: crumbLbl
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            color: crumbHov.containsMouse ? win.pal.accent : win.pal.text
                                            font.pixelSize: 12
                                        }
                                        MouseArea {
                                            id: crumbHov
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: win.navigate(modelData.id)
                                        }
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Search box
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 26
                        color: win.pal.content
                        border.color: searchFld.activeFocus ? win.pal.accent : win.pal.borderSoft
                        radius: 3

                        TextField {
                            id: searchFld
                            anchors.fill: parent
                            anchors.rightMargin: 26
                            placeholderText: win.currentNode ? ("Buscar en " + win.currentNode.name) : "Buscar"
                            background: Item {}
                            color: win.pal.text
                            font.pixelSize: 12
                            leftPadding: 8
                            onTextChanged: win.searchQuery = text
                        }

                        // SVG magnifying glass icon
                        Canvas {
                            anchors.right: parent.right
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14; height: 14
                            property color fg: win.pal.muted
                            onFgChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, 14, 14)
                                ctx.strokeStyle = fg
                                ctx.lineWidth = 1.6
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(6, 6, 4, 0, Math.PI * 2)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(9, 9)
                                ctx.lineTo(12.5, 12.5)
                                ctx.stroke()
                            }
                        }
                    }
                }
            }

            // ==================== COMMAND BAR ====================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                border.color: win.pal.borderSoft
                gradient: Gradient {
                    GradientStop { position: 0; color: win.pal.tbar1 }
                    GradientStop { position: 1; color: win.pal.tbar2 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 2

                    // Command buttons
                    Repeater {
                        model: [
                            { label: "Organizar", chevron: true, always: true, bold: true, action: function(){} },
                            { sep: true },
                            { label: "Abrir", chevron: true, requireSel: true, action: function(){} },
                            { label: "Compartir con", requireSel: true, action: function(){ win.handleCopy() } },
                            { label: "Imprimir", requireSel: true, action: function(){ win.showToast("Imprimir...") } },
                            { label: "Correo", requireSel: true, action: function(){ win.showToast("Enviar por correo...") } },
                            { label: "Eliminar", requireSel: true, action: function(){ win.handleDelete() } },
                            { label: "Nueva carpeta", always: true, action: function(){ win.handleNewFolder() } }
                        ]
                        delegate: Loader {
                            sourceComponent: modelData.sep ? sepComp : btnComp
                            Component {
                                id: sepComp
                                Rectangle { implicitWidth: 1; implicitHeight: 18; color: win.pal.border }
                            }
                            Component {
                                id: btnComp
                                Rectangle {
                                    property bool isEnabled: modelData.always || win.selectedCount > 0
                                    implicitWidth: btnRow.implicitWidth + 16
                                    implicitHeight: 26
                                    color: btnHov.containsMouse && isEnabled ? win.pal.accentSoft : "transparent"
                                    border.color: btnHov.containsMouse && isEnabled ? win.pal.border : "transparent"
                                    radius: 2
                                    opacity: isEnabled ? 1 : 0.4

                                    Row {
                                        id: btnRow
                                        anchors.centerIn: parent
                                        spacing: 3

                                        Label {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            color: win.pal.text
                                            font.pixelSize: 12
                                            font.bold: modelData.bold || false
                                        }

                                        // Chevron for buttons that have it
                                        Canvas {
                                            visible: modelData.chevron || false
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 8; height: 6
                                            property color fg: win.pal.muted
                                            onFgChanged: requestPaint()
                                            Component.onCompleted: requestPaint()
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.clearRect(0, 0, 8, 6)
                                                ctx.strokeStyle = fg
                                                ctx.lineWidth = 1.3
                                                ctx.lineCap = "round"
                                                ctx.beginPath()
                                                ctx.moveTo(1, 1.5)
                                                ctx.lineTo(4, 4.5)
                                                ctx.lineTo(7, 1.5)
                                                ctx.stroke()
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: btnHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: parent.isEnabled
                                        onClicked: modelData.action()
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Preview panel toggle (SVG: two rects, right one shaded)
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 26
                        color: prevHov.containsMouse || win.showPreview ? win.pal.accentSoft : "transparent"
                        border.color: prevHov.containsMouse || win.showPreview ? win.pal.border : "transparent"
                        radius: 2

                        Canvas {
                            anchors.centerIn: parent
                            width: 18; height: 14
                            property color fg: win.pal.muted
                            onFgChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, 18, 14)
                                ctx.strokeStyle = fg
                                ctx.lineWidth = 1.2
                                ctx.strokeRect(0.5, 0.5, 17, 13)
                                ctx.fillStyle = Qt.rgba(
                                    parseInt(fg.toString().slice(1,3), 16)/255,
                                    parseInt(fg.toString().slice(3,5), 16)/255,
                                    parseInt(fg.toString().slice(5,7), 16)/255,
                                    0.18)
                                ctx.fillRect(10, 0.5, 7.5, 13)
                            }
                        }

                        MouseArea {
                            id: prevHov
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.showPreview = !win.showPreview
                        }
                    }

                    // View switcher: icon + chevron → dropdown
                    Row {
                        spacing: 0

                        Rectangle {
                            width: 28; height: 26
                            color: vsIconHov.containsMouse ? win.pal.accentSoft : "transparent"
                            border.color: vsIconHov.containsMouse ? win.pal.border : "transparent"
                            radius: 2

                            Canvas {
                                id: vsCanvas
                                anchors.centerIn: parent
                                width: 16; height: 16
                                property string vm: win.viewMode
                                property color fg: win.pal.muted
                                onVmChanged: requestPaint()
                                onFgChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, 16, 16)
                                    ctx.fillStyle = fg
                                    var m = vm
                                    if (m === "large" || m === "medium") {
                                        var s = m === "large" ? 4.5 : 3.5
                                        var xs = [1, 8 - s/2, 15 - s]
                                        var ys = [1, 8 - s/2]
                                        for (var yi = 0; yi < ys.length; yi++)
                                            for (var xi = 0; xi < xs.length; xi++)
                                                ctx.fillRect(xs[xi], ys[yi], s, s)
                                    } else if (m === "list") {
                                        ctx.fillRect(1,2,3,3); ctx.fillRect(5,3,10,1)
                                        ctx.fillRect(1,7,3,3); ctx.fillRect(5,8,10,1)
                                        ctx.fillRect(1,12,3,3); ctx.fillRect(5,13,10,1)
                                    } else if (m === "details") {
                                        ctx.fillRect(1,2,2,2); ctx.fillRect(4,2.5,11,1)
                                        ctx.fillRect(1,6,2,2); ctx.fillRect(4,6.5,11,1)
                                        ctx.fillRect(1,10,2,2); ctx.fillRect(4,10.5,11,1)
                                        ctx.fillRect(1,14,2,1.2); ctx.fillRect(4,14,11,1.2)
                                    } else {
                                        ctx.fillRect(1,2,4,4); ctx.fillRect(6,2.5,9,1); ctx.fillRect(6,4.5,7,1)
                                        ctx.fillRect(1,8,4,4); ctx.fillRect(6,8.5,9,1); ctx.fillRect(6,10.5,7,1)
                                    }
                                }
                            }

                            MouseArea {
                                id: vsIconHov
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: viewMenu.popup()
                            }
                        }

                        // Chevron dropdown trigger
                        Rectangle {
                            width: 16; height: 26
                            color: vsChevHov.containsMouse ? win.pal.accentSoft : "transparent"
                            border.color: vsChevHov.containsMouse ? win.pal.border : "transparent"
                            radius: 2

                            Canvas {
                                anchors.centerIn: parent
                                width: 8; height: 6
                                property color fg: win.pal.muted
                                onFgChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, 8, 6)
                                    ctx.strokeStyle = fg
                                    ctx.lineWidth = 1.3
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.moveTo(1, 1.5)
                                    ctx.lineTo(4, 4.5)
                                    ctx.lineTo(7, 1.5)
                                    ctx.stroke()
                                }
                            }

                            MouseArea {
                                id: vsChevHov
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: viewMenu.popup()
                            }
                        }
                    }

                    // View dropdown menu
                    Menu {
                        id: viewMenu
                        MenuItem { text: "Iconos grandes";  checkable: true; checked: win.viewMode === "large";   onTriggered: win.viewMode = "large" }
                        MenuItem { text: "Iconos medianos"; checkable: true; checked: win.viewMode === "medium";  onTriggered: win.viewMode = "medium" }
                        MenuItem { text: "Lista";           checkable: true; checked: win.viewMode === "list";    onTriggered: win.viewMode = "list" }
                        MenuItem { text: "Detalles";        checkable: true; checked: win.viewMode === "details"; onTriggered: win.viewMode = "details" }
                        MenuItem { text: "Contenido";       checkable: true; checked: win.viewMode === "content"; onTriggered: win.viewMode = "content" }
                    }

                    // Help button (circle + ?)
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 26
                        color: helpHov.containsMouse ? win.pal.accentSoft : "transparent"
                        border.color: helpHov.containsMouse ? win.pal.border : "transparent"
                        radius: 2

                        Canvas {
                            anchors.centerIn: parent
                            width: 16; height: 16
                            property color fg: win.pal.muted
                            onFgChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, 16, 16)
                                ctx.strokeStyle = fg
                                ctx.lineWidth = 1.4
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(8, 8, 6.5, 0, Math.PI * 2)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(6, 6)
                                ctx.quadraticCurveTo(6, 4, 8, 4)
                                ctx.quadraticCurveTo(10, 4, 10, 6)
                                ctx.quadraticCurveTo(10, 7.5, 8, 8)
                                ctx.lineTo(8, 9.5)
                                ctx.stroke()
                                ctx.fillStyle = fg
                                ctx.beginPath()
                                ctx.arc(8, 12, 0.8, 0, Math.PI * 2)
                                ctx.fill()
                            }
                        }

                        MouseArea {
                            id: helpHov
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.showToast("Win7 File Explorer — Qt 6 QML")
                        }
                    }
                }
            }

            // ==================== BODY ====================
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

// SIDEBAR
    Rectangle {
      visible: win.showSidebar
      Layout.preferredWidth: 200
      Layout.fillHeight: true
      border.color: win.pal.borderSoft
      gradient: Gradient {
        GradientStop { position: 0; color: win.pal.sidebar }
        GradientStop { position: 1; color: win.pal.sidebar }
      }

      ScrollView {
        anchors.fill: parent
        clip: true
        Column {
          width: 200
          topPadding: 6
          bottomPadding: 6
          spacing: 2
          
          // Favorites section
          Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 6
              
              Image {
                source: "qrc:/icons/favorites.png"
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
              }
              Label {
                text: "Favoritos"
                color: win.pal.sbText
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
              }
            }
          }
          
          // Desktop
          Rectangle {
            width: parent.width
            height: 22
            color: win.currentId === "desktop" ? win.pal.sbCurrent : (desktopHov.containsMouse ? win.pal.sbHover : "transparent")
            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: 2
              color: win.currentId === "desktop" ? win.pal.selectionBorder : "transparent"
            }
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 22
              anchors.rightMargin: 6
              spacing: 6
              Image {
                source: "qrc:/icons/desktop.png"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                fillMode: Image.PreserveAspectFit
              }
              Label {
                text: "Escritorio"
                color: win.currentId === "desktop" ? win.pal.selText : win.pal.sbText
                font.pixelSize: 12
                font.bold: win.currentId === "desktop"
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }
            MouseArea {
              id: desktopHov
              anchors.fill: parent
              hoverEnabled: true
              onClicked: win.navigate("desktop")
            }
          }
          
          // Downloads
          Rectangle {
            width: parent.width
            height: 22
            color: win.currentId === "downloads" ? win.pal.sbCurrent : (downloadsHov.containsMouse ? win.pal.sbHover : "transparent")
            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: 2
              color: win.currentId === "downloads" ? win.pal.selectionBorder : "transparent"
            }
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 22
              anchors.rightMargin: 6
              spacing: 6
              Image {
                source: "qrc:/icons/downloads.png"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                fillMode: Image.PreserveAspectFit
              }
              Label {
                text: "Descargas"
                color: win.currentId === "downloads" ? win.pal.selText : win.pal.sbText
                font.pixelSize: 12
                font.bold: win.currentId === "downloads"
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }
            MouseArea {
              id: downloadsHov
              anchors.fill: parent
              hoverEnabled: true
              onClicked: win.navigate("downloads")
            }
          }
          
          // Libraries section
          Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 6
              
              Image {
                source: "qrc:/icons/libraries.png"
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
              }
              Label {
                text: "Bibliotecas"
                color: win.pal.sbText
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
              }
            }
          }
          
          // Libraries items
          Repeater {
            model: win.libraries
            delegate: Rectangle {
              width: parent.width
              height: 22
              color: win.currentId === modelData.path ? win.pal.sbCurrent : (libHov.containsMouse ? win.pal.sbHover : "transparent")
              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: win.currentId === modelData.path ? win.pal.selectionBorder : "transparent"
              }
              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 6
                spacing: 6
                Image {
                  source: "qrc:/icons/" + modelData.icon + ".png"
                  Layout.preferredWidth: 16
                  Layout.preferredHeight: 16
                  fillMode: Image.PreserveAspectFit
                }
                Label {
                  text: modelData.name
                  color: win.currentId === modelData.path ? win.pal.selText : win.pal.sbText
                  font.pixelSize: 12
                  font.bold: win.currentId === modelData.path
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }
              MouseArea {
                id: libHov
                anchors.fill: parent
                hoverEnabled: true
                onClicked: win.navigate(modelData.path)
              }
            }
          }
          
          // Computer section
          Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 6
              
              Image {
                source: "qrc:/icons/computer.png"
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
              }
              Label {
                text: "Equipo"
                color: win.pal.sbText
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
              }
            }
          }
          
          // Computer - drives
          Repeater {
            model: win.storageDevices
            delegate: Rectangle {
              width: parent.width
              height: 22
              color: win.currentId === modelData.path ? win.pal.sbCurrent : (driveHov.containsMouse ? win.pal.sbHover : "transparent")
              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 2
                color: win.currentId === modelData.path ? win.pal.selectionBorder : "transparent"
              }
              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 6
                spacing: 6
                Image {
                  source: "qrc:/icons/drive-" + modelData.kind + ".png"
                  Layout.preferredWidth: 16
                  Layout.preferredHeight: 16
                  fillMode: Image.PreserveAspectFit
                }
                Label {
                  text: modelData.label
                  color: win.currentId === modelData.path ? win.pal.selText : win.pal.sbText
                  font.pixelSize: 12
                  font.bold: win.currentId === modelData.path
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }
              MouseArea {
                id: driveHov
                anchors.fill: parent
                hoverEnabled: true
                onClicked: win.navigate(modelData.path)
              }
            }
          }
          
          // Original folder tree (for compatibility)
          Repeater {
            model: fs.root.children
            delegate: SidebarGroup {
              group: modelData
              width: parent.width
              pal: win.pal
              fs: fs
              currentId: win.currentId
              navigateFn: win.navigate
            }
          }
        }
      }
    }

                // MAIN CONTENT AREA
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: win.pal.content

                        Loader {
                            anchors.fill: parent
                            anchors.margins: 8
                            sourceComponent: {
                                if (win.items.length === 0) return emptyView
                                if (win.currentNode && win.currentNode.type === "group") return groupedView
                                if (win.viewMode === "details") return detailsView
                                if (win.viewMode === "list") return listView
                                if (win.viewMode === "content") return contentView
                                return iconsView
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    ctxMenu.targetItem = null
                                    ctxMenu.popup()
                                }
                            }
                        }
                    }
                }

                // PREVIEW PANEL
                Rectangle {
                    id: previewPanel
                    visible: win.showPreview
                    Layout.preferredWidth: 240
                    Layout.fillHeight: true
                    color: win.pal.panel
                    border.color: win.pal.borderSoft

                    property var previewItem: {
                        if (win.selectedCount !== 1) return null
                        var id = Object.keys(win.selectedIds)[0]
                        return win.items.find(function(i){ return i.id === id }) || null
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        // Hero preview area
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180

                            // Empty state: file-preview placeholder SVG
                            Column {
                                visible: previewPanel.previewItem === null
                                anchors.centerIn: parent
                                spacing: 10

                                Canvas {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 48; height: 48
                                    property color fg: win.pal.muted
                                    onFgChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, 48, 48)
                                        ctx.strokeStyle = fg
                                        ctx.globalAlpha = 0.4
                                        ctx.lineWidth = 1.2
                                        ctx.strokeRect(8, 6, 32, 36)
                                        ctx.beginPath()
                                        ctx.moveTo(16, 16); ctx.lineTo(32, 16)
                                        ctx.moveTo(16, 22); ctx.lineTo(32, 22)
                                        ctx.moveTo(16, 28); ctx.lineTo(26, 28)
                                        ctx.stroke()
                                    }
                                }

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Selecciona un archivo\npara previsualizar"
                                    color: win.pal.muted
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 12
                                }
                            }

                            // File icon
                            Image {
                                visible: previewPanel.previewItem !== null
                                anchors.centerIn: parent
                                width: 96; height: 96
                                fillMode: Image.PreserveAspectFit
                                source: previewPanel.previewItem ? fs.iconFor(previewPanel.previewItem) : ""
                            }
                        }

                        // File name
                        Label {
                            visible: previewPanel.previewItem !== null
                            Layout.fillWidth: true
                            text: previewPanel.previewItem ? previewPanel.previewItem.name : ""
                            color: win.pal.text
                            font.pixelSize: 12; font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }

                        // File type
                        Label {
                            visible: previewPanel.previewItem !== null
                            Layout.fillWidth: true
                            text: previewPanel.previewItem ? fs.typeLabel(previewPanel.previewItem) : ""
                            color: win.pal.muted
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // File metadata (size, date, dimensions, duration)
                        Column {
                            visible: previewPanel.previewItem !== null
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: {
                                    var it = previewPanel.previewItem
                                    if (!it) return []
                                    var rows = []
                                    if (it.modified) rows.push({ lbl: "Modificado", val: it.modified })
                                    if (it.size)     rows.push({ lbl: "Tamaño",     val: it.size })
                                    if (it.dim)      rows.push({ lbl: "Dimensiones",val: it.dim })
                                    if (it.duration) rows.push({ lbl: "Duración",   val: it.duration })
                                    return rows
                                }
                                delegate: RowLayout {
                                    width: parent.width
                                    Label {
                                        text: modelData.lbl + ":"
                                        color: win.pal.muted
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 80
                                    }
                                    Label {
                                        text: modelData.val
                                        color: win.pal.text
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ==================== STATUS BAR ====================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: win.selectedCount === 1 ? 58 : 26
                border.color: win.pal.borderSoft
                gradient: Gradient {
                    GradientStop { position: 0; color: win.pal.stat1 }
                    GradientStop { position: 1; color: win.pal.stat2 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 10

                    // No selection: count
                    Label {
                        visible: win.selectedCount === 0
                        text: win.items.length + " elemento" + (win.items.length === 1 ? "" : "s")
                        color: win.pal.muted
                        font.pixelSize: 11
                    }

                    // Multi-selection count
                    Label {
                        visible: win.selectedCount > 1
                        text: win.selectedCount + " elementos seleccionados"
                        color: win.pal.muted
                        font.pixelSize: 11
                    }

                    // Single item detail
                    Image {
                        visible: win.selectedCount === 1
                        source: {
                            if (win.selectedCount !== 1) return ""
                            var id = Object.keys(win.selectedIds)[0]
                            var it = win.items.find(function(i){ return i.id === id })
                            return it ? fs.iconFor(it) : ""
                        }
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        visible: win.selectedCount === 1
                        Layout.fillWidth: true
                        spacing: 2

                        property var selItem: {
                            if (win.selectedCount !== 1) return null
                            var id = Object.keys(win.selectedIds)[0]
                            return win.items.find(function(i){ return i.id === id }) || null
                        }

                        Label {
                            text: parent.selItem ? parent.selItem.name : ""
                            color: win.pal.text
                            font.pixelSize: 12; font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 12

                            Repeater {
                                model: {
                                    var it = parent.parent.selItem
                                    if (!it) return []
                                    var parts = [{ lbl: "Tipo", val: fs.typeLabel(it) }]
                                    if (it.modified) parts.push({ lbl: "Modificado", val: it.modified })
                                    if (it.size)     parts.push({ lbl: "Tamaño",     val: it.size })
                                    if (it.dim)      parts.push({ lbl: "Dim",        val: it.dim })
                                    if (it.duration) parts.push({ lbl: "Duración",   val: it.duration })
                                    return parts
                                }
                                delegate: Row {
                                    spacing: 4
                                    Label { text: modelData.lbl + ":"; color: win.pal.muted; font.pixelSize: 11 }
                                    Label { text: modelData.val;       color: win.pal.text;  font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

// ==================== CONTEXT MENU ====================
  Menu {
    id: ctxMenu
    property var targetItem: null
    property bool hasSelection: win.selectedCount > 0
    property bool isFolder: ctxMenu.targetItem && ctxMenu.targetItem.type === "folder"
    property bool isFile: ctxMenu.targetItem && ctxMenu.targetItem.type !== "folder"
    
    // Estilo Windows 7 Aero
    palette.window: win.pal.panel
    palette.windowText: win.pal.text
    palette.base: win.pal.content
    palette.text: win.pal.text
    palette.highlight: win.pal.accentSoft
    palette.highlightedText: win.pal.accent
    
    MenuItem {
      text: "Abrir"
      enabled: ctxMenu.targetItem !== null
      icon.source: "qrc:/icons/open.png"
      onTriggered: win.doubleClickItem(ctxMenu.targetItem)
    }
    MenuItem {
      text: "Abrir en una nueva ventana"
      enabled: ctxMenu.isFolder
      icon.source: "qrc:/icons/open-new-window.png"
      onTriggered: win.showToast("Abrir en nueva ventana...")
    }
    MenuSeparator {}
    MenuItem {
      text: "Cortar"
      enabled: ctxMenu.hasSelection
      icon.source: "qrc:/icons/cut.png"
      onTriggered: win.showToast("Cortar...")
    }
    MenuItem {
      text: "Copiar"
      enabled: ctxMenu.hasSelection
      icon.source: "qrc:/icons/copy.png"
      onTriggered: win.handleCopy()
    }
    MenuItem {
      text: "Pegar"
      enabled: true
      icon.source: "qrc:/icons/paste.png"
      onTriggered: win.showToast("Pegar...")
    }
    MenuSeparator {}
    MenuItem {
      text: "Crear acceso directo"
      enabled: ctxMenu.targetItem !== null
      icon.source: "qrc:/icons/shortcut.png"
      onTriggered: win.showToast("Crear acceso directo...")
    }
    MenuItem {
      text: "Eliminar"
      enabled: ctxMenu.hasSelection
      icon.source: "qrc:/icons/delete.png"
      onTriggered: win.handleDelete()
    }
    MenuItem {
      text: "Cambiar nombre"
      enabled: ctxMenu.targetItem !== null
      icon.source: "qrc:/icons/rename.png"
      onTriggered: win.showToast("Cambiar nombre...")
    }
    MenuSeparator {}
    MenuItem {
      text: "Propiedades"
      enabled: ctxMenu.targetItem !== null
      icon.source: "qrc:/icons/properties.png"
      onTriggered: win.showToast("Propiedades...")
    }
    MenuSeparator {
      visible: ctxMenu.isFolder
    }
    MenuItem {
      text: "Nueva carpeta"
      visible: ctxMenu.isFolder || ctxMenu.targetItem === null
      icon.source: "qrc:/icons/new-folder.png"
      onTriggered: win.handleNewFolder()
    }
  }

    // ==================== TOAST ====================
    Rectangle {
        visible: win.toastMsg.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        color: win.pal.panel
        border.color: win.pal.border
        radius: 20
        implicitWidth: toastLabel.implicitWidth + 36
        implicitHeight: 36
        Label {
            id: toastLabel
            anchors.centerIn: parent
            text: win.toastMsg
            color: win.pal.text
            font.pixelSize: 12
        }
    }

    // ==================== VIEW COMPONENTS ====================

    Component {
        id: emptyView
        Item {
            Label {
                anchors.centerIn: parent
                text: win.searchQuery ? ("Sin resultados para \"" + win.searchQuery + "\"") : "Esta carpeta está vacía"
                color: win.pal.muted
                font.pixelSize: 13
            }
        }
    }

    Component {
        id: iconsView
        GridView {
            cellWidth: win.viewMode === "large" ? 110 : 82
            cellHeight: win.viewMode === "large" ? 100 : 78
            clip: true
            model: win.items
            delegate: Rectangle {
                width: GridView.view.cellWidth - 6
                height: GridView.view.cellHeight - 6
                color: win.isSelected(modelData.id) ? win.pal.selection : (tileArea.containsMouse ? win.pal.accentSoft : "transparent")
                border.color: win.isSelected(modelData.id) ? win.pal.selectionBorder : "transparent"
                radius: 3
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        source: fs.iconFor(modelData)
                        sourceSize.width: win.viewMode === "large" ? 64 : 40
                        sourceSize.height: win.viewMode === "large" ? 64 : 40
                        Layout.preferredWidth: win.viewMode === "large" ? 64 : 40
                        Layout.preferredHeight: win.viewMode === "large" ? 64 : 40
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.text
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        win.toggleSelect(modelData.id, mouse.modifiers & Qt.ControlModifier, mouse.modifiers & Qt.ShiftModifier)
                        if (mouse.button === Qt.RightButton) { ctxMenu.targetItem = modelData; ctxMenu.popup() }
                    }
                    onDoubleClicked: win.doubleClickItem(modelData)
                }
            }
        }
    }

    Component {
        id: listView
        ListView {
            clip: true
            model: win.items
            delegate: Rectangle {
                width: ListView.view.width
                height: 22 * win.densityMul
                color: win.isSelected(modelData.id) ? win.pal.selection : (listArea.containsMouse ? win.pal.accentSoft : "transparent")
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 6
                    Image { source: fs.iconFor(modelData); Layout.preferredWidth: 16; Layout.preferredHeight: 16; fillMode: Image.PreserveAspectFit }
                    Label { text: modelData.name; color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.text; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                MouseArea {
                    id: listArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        win.toggleSelect(modelData.id, mouse.modifiers & Qt.ControlModifier, mouse.modifiers & Qt.ShiftModifier)
                        if (mouse.button === Qt.RightButton) { ctxMenu.targetItem = modelData; ctxMenu.popup() }
                    }
                    onDoubleClicked: win.doubleClickItem(modelData)
                }
            }
        }
    }

    Component {
        id: detailsView
        ColumnLayout {
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                gradient: Gradient {
                    GradientStop { position: 0; color: win.pal.tbar1 }
                    GradientStop { position: 1; color: win.pal.tbar2 }
                }
                border.color: win.pal.borderSoft
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Repeater {
                        model: [
                            { id: "name", label: "Nombre", stretch: 3 },
                            { id: "modified", label: "Fecha de modificación", stretch: 2 },
                            { id: "type", label: "Tipo", stretch: 1 },
                            { id: "size", label: "Tamaño", stretch: 1 }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: modelData.stretch * 100
                            Layout.fillHeight: true
                            color: colHov.containsMouse ? win.pal.accentSoft : "transparent"
                            border.color: win.pal.borderSoft
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                Label {
                                    text: modelData.label
                                    color: win.sortBy === modelData.id ? win.pal.accent : win.pal.text
                                    font.pixelSize: 11; font.bold: true
                                    Layout.fillWidth: true
                                }
                                Label { visible: win.sortBy === modelData.id; text: win.sortDir === "asc" ? "▲" : "▼"; color: win.pal.accent; font.pixelSize: 9 }
                            }
                            MouseArea { id: colHov; anchors.fill: parent; hoverEnabled: true; onClicked: win.setSort(modelData.id) }
                        }
                    }
                }
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.items
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 24 * win.densityMul
                    color: win.isSelected(modelData.id) ? win.pal.selection : (detArea.containsMouse ? win.pal.accentSoft : "transparent")
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true; Layout.preferredWidth: 300
                            Layout.leftMargin: 8; spacing: 6
                            Image { source: fs.iconFor(modelData); Layout.preferredWidth: 16; Layout.preferredHeight: 16; fillMode: Image.PreserveAspectFit }
                            Label { text: modelData.name; color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.text; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                        Label { Layout.fillWidth: true; Layout.preferredWidth: 200; Layout.leftMargin: 8; text: modelData.modified || "—"; color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.muted; font.pixelSize: 11 }
                        Label { Layout.fillWidth: true; Layout.preferredWidth: 100; Layout.leftMargin: 8; text: fs.typeLabel(modelData); color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.muted; font.pixelSize: 11 }
                        Label { Layout.fillWidth: true; Layout.preferredWidth: 100; Layout.leftMargin: 8; Layout.rightMargin: 8; text: modelData.size || (modelData.type === "folder" ? "" : "—"); color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.muted; font.pixelSize: 11 }
                    }
                    MouseArea {
                        id: detArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            win.toggleSelect(modelData.id, mouse.modifiers & Qt.ControlModifier, mouse.modifiers & Qt.ShiftModifier)
                            if (mouse.button === Qt.RightButton) { ctxMenu.targetItem = modelData; ctxMenu.popup() }
                        }
                        onDoubleClicked: win.doubleClickItem(modelData)
                    }
                }
            }
        }
    }

    Component {
        id: contentView
        ListView {
            clip: true
            model: win.items
            spacing: 0
            delegate: Rectangle {
                width: ListView.view.width
                height: 64
                color: win.isSelected(modelData.id) ? win.pal.selection : (cvHov.containsMouse ? win.pal.accentSoft : "transparent")
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: win.pal.borderSoft
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 14
                    Image { source: fs.iconFor(modelData); Layout.preferredWidth: 44; Layout.preferredHeight: 44; fillMode: Image.PreserveAspectFit }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: modelData.name; color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.text; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label {
                            text: {
                                var parts = [fs.typeLabel(modelData)]
                                if (modelData.size) parts.push(modelData.size)
                                if (modelData.modified) parts.push("Modificado: " + modelData.modified)
                                return parts.join("  ·  ")
                            }
                            color: win.isSelected(modelData.id) ? win.pal.selText : win.pal.muted
                            font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                }
                MouseArea {
                    id: cvHov
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        win.toggleSelect(modelData.id, mouse.modifiers & Qt.ControlModifier, mouse.modifiers & Qt.ShiftModifier)
                        if (mouse.button === Qt.RightButton) { ctxMenu.targetItem = modelData; ctxMenu.popup() }
                    }
                    onDoubleClicked: win.doubleClickItem(modelData)
                }
            }
        }
    }

    Component {
        id: groupedView
        ScrollView {
            clip: true
            Column {
                width: parent.width
                spacing: 18
                Repeater {
                    model: [
                        { title: "Unidades de disco duro", filter: function(i){ return i.type === "drive" && i.kind !== "disc" } },
                        { title: "Dispositivos con almacenamiento extraíble", filter: function(i){ return i.type === "drive" && i.kind === "disc" } },
                        { title: "Ubicaciones de red", filter: function(i){ return i.kind === "pc" || i.kind === "printer" } },
                        { title: "Carpetas", filter: function(i){ return i.type === "folder" } }
                    ]
                    delegate: Column {
                        width: parent.width
                        spacing: 8
                        property var subset: win.items.filter(modelData.filter)
                        visible: subset.length > 0
                        Label {
                            text: modelData.title + "  (" + parent.subset.length + ")"
                            color: win.pal.accent
                            font.pixelSize: 12; font.bold: true
                            leftPadding: 12
                        }
                        Flow {
                            width: parent.width
                            spacing: 14
                            leftPadding: 8
                            Repeater {
                                model: parent.parent.subset
                                delegate: Rectangle {
                                    width: 260; height: 64
                                    color: win.isSelected(modelData.id) ? win.pal.selection : (grArea.containsMouse ? win.pal.accentSoft : "transparent")
                                    border.color: win.isSelected(modelData.id) ? win.pal.selectionBorder : "transparent"
                                    radius: 3
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10
                                        Image { source: fs.iconFor(modelData); Layout.preferredWidth: 52; Layout.preferredHeight: 52; fillMode: Image.PreserveAspectFit }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Label { text: modelData.name; color: win.pal.text; font.pixelSize: 12; font.bold: true }
                                            Rectangle {
                                                visible: modelData.total !== undefined
                                                Layout.fillWidth: true; Layout.preferredHeight: 6
                                                color: win.pal.borderSoft; radius: 3
                                                Rectangle {
                                                    width: parent.width * (modelData.total ? (modelData.total - modelData.free) / modelData.total : 0)
                                                    height: parent.height; radius: 3
                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal
                                                        GradientStop { position: 0; color: "#4fd1e8" }
                                                        GradientStop { position: 1; color: "#1a8ab8" }
                                                    }
                                                }
                                            }
                                            Label {
                                                visible: modelData.total !== undefined
                                                text: modelData.free + " GB libres de " + modelData.total + " GB"
                                                color: win.pal.muted; font.pixelSize: 10
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: grArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: win.toggleSelect(modelData.id, false, false)
                                        onDoubleClicked: win.doubleClickItem(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
