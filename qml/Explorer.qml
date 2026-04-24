// Explorer.qml - Explorador de archivos en Qt 6 QML
// Port del prototipo HTML: chrome, sidebar, breadcrumbs, múltiples vistas,
// panel de preview, status bar, menú contextual y 5 temas.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: win
    width: 1180
    height: 760
    visible: true
    title: currentNode ? currentNode.name : "Explorador"
    flags: Qt.Window | Qt.FramelessWindowHint

    // ---------- Modelo ----------
    FileSystem { id: fs }

    // ---------- Estado ----------
    property var historyStack: [["libraries"]]
    property int historyIndex: 0
    property string currentId: historyStack[historyIndex][historyStack[historyIndex].length - 1]
    property var currentNode: fs.findNode(currentId)
    property var pathToCurrent: fs.pathTo(currentId) || []

    property string viewMode: "large"   // large|medium|list|details|content
    property var selectedIds: ({})
    property int selectedCount: 0
    property string searchQuery: ""
    property string sortBy: "name"
    property string sortDir: "asc"

    // ---------- Tweaks ----------
    property string themeName: "glass"
    property string density: "comfortable"
    property int accentHue: 230
    property int radiusVal: 6
    property bool showSidebar: true
    property bool showPreview: true

    // ---------- Paletas ----------
    readonly property var palettes: ({
        glass: {
            bg1: "#e8f0fa", bg2: "#c8d9ee",
            titlebar: "#e4ecf7", titleText: "#2a3a4d",
            panel: "#f6f9fc", border: "#c0ccd9", borderSoft: "#e2e8f0",
            sidebar: "#eef4fb", sbText: "#26334a",
            sbHover: "#d4e4f5", sbCurrent: "#b8d4f0",
            toolbar: "#eef4fb", cmdHover: "#d4e4f5",
            content: "#ffffff", text: "#1e2836", muted: "#6a7788",
            selection: "#b8d4f0", selectionBorder: "#5a9bd4", selText: "#0c2a4a",
            accent: "#3f7cb8", accentSoft: "#d4e6f7",
            status: "#e8eff7"
        },
        flat: {
            bg1: "#f5f7fa", bg2: "#f5f7fa",
            titlebar: "#ffffff", titleText: "#1e2836",
            panel: "#ffffff", border: "#e2e8f0", borderSoft: "#eef2f6",
            sidebar: "#fafbfc", sbText: "#1e2836",
            sbHover: "#eef2f6", sbCurrent: "#e7f0fb",
            toolbar: "#ffffff", cmdHover: "#eef2f6",
            content: "#ffffff", text: "#1e2836", muted: "#6a7788",
            selection: "#e7f0fb", selectionBorder: "#86b4e2", selText: "#13243a",
            accent: "#3f7cb8", accentSoft: "#e7f0fb",
            status: "#fafbfc"
        },
        dark: {
            bg1: "#1a1f2b", bg2: "#0f131c",
            titlebar: "#1e2430", titleText: "#d9e1ed",
            panel: "#1e242f", border: "#2d3441", borderSoft: "#262d3b",
            sidebar: "#1c222d", sbText: "#c8d0dd",
            sbHover: "#262d3b", sbCurrent: "#2d3e5e",
            toolbar: "#1e242f", cmdHover: "#262d3b",
            content: "#161b24", text: "#d9e1ed", muted: "#8a94a6",
            selection: "#2d3e5e", selectionBorder: "#5a7eb8", selText: "#e8eef8",
            accent: "#6ba7e0", accentSoft: "#2d3e5e",
            status: "#1c222d"
        },
        warm: {
            bg1: "#faf2e0", bg2: "#ebdec2",
            titlebar: "#f5ebd0", titleText: "#3d3220",
            panel: "#fcf7eb", border: "#d4c6a4", borderSoft: "#e4d7b8",
            sidebar: "#f9f2e0", sbText: "#3d3220",
            sbHover: "#f1e7cd", sbCurrent: "#e8d8b0",
            toolbar: "#fbf5e8", cmdHover: "#f1e7cd",
            content: "#fffaed", text: "#3d3220", muted: "#7d6b48",
            selection: "#f0d998", selectionBorder: "#b39040", selText: "#3d2a0a",
            accent: "#b37c1d", accentSoft: "#f5e4ba",
            status: "#f9f2e0"
        },
        neon: {
            bg1: "#080d18", bg2: "#030509",
            titlebar: "#0a0f1a", titleText: "#7ee8d8",
            panel: "#0a0f1a", border: "#1a2540", borderSoft: "#18203a",
            sidebar: "#0a0f1a", sbText: "#a0b4c8",
            sbHover: "#122038", sbCurrent: "#1a3358",
            toolbar: "#0a0f1a", cmdHover: "#122038",
            content: "#05080f", text: "#c8e8f5", muted: "#6a8aa8",
            selection: "#132030", selectionBorder: "#7ee8d8", selText: "#7ee8d8",
            accent: "#7ee8d8", accentSoft: "#132030",
            status: "#080d18"
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
        // refrescar currentNode
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
        radius: win.radiusVal

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ---------- TITLEBAR ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: win.pal.titlebar
                border.color: win.pal.border

                MouseArea {
                    anchors.fill: parent
                    property point startPos
                    onPressed: (mouse) => { startPos = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            win.x += mouse.x - startPos.x
                            win.y += mouse.y - startPos.y
                        }
                    }
                    onDoubleClicked: win.visibility = (win.visibility === Window.Maximized ? Window.Windowed : Window.Maximized)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 4

                    Label {
                        text: win.title
                        color: win.pal.titleText
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: [
                            { label: "—", action: function(){ win.showMinimized() } },
                            { label: "□", action: function(){ win.visibility = win.visibility === Window.Maximized ? Window.Windowed : Window.Maximized } },
                            { label: "✕", action: function(){ Qt.quit() }, close: true }
                        ]
                        delegate: Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 26
                            color: hoverArea.containsMouse ? (modelData.close ? "#e23d3d" : Qt.rgba(100/255, 140/255, 180/255, 0.2)) : "transparent"
                            radius: 2
                            Label {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: modelData.close && hoverArea.containsMouse ? "white" : win.pal.titleText
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: modelData.action()
                            }
                        }
                    }
                }
            }

            // ---------- ADDRESS BAR ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: win.pal.toolbar
                border.color: win.pal.borderSoft

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Nav arrows
                    RowLayout {
                        spacing: 2
                        Repeater {
                            model: [
                                { label: "◀", enabled: win.historyIndex > 0, action: function(){ win.goBack() } },
                                { label: "▶", enabled: win.historyIndex < win.historyStack.length - 1, action: function(){ win.goForward() } },
                                { label: "▲", enabled: win.pathToCurrent.length > 1, action: function(){ win.goUp() } }
                            ]
                            delegate: Rectangle {
                                Layout.preferredWidth: 26; Layout.preferredHeight: 26
                                radius: 13
                                color: arrowArea.containsMouse && modelData.enabled ? win.pal.cmdHover : "transparent"
                                border.color: arrowArea.containsMouse && modelData.enabled ? win.pal.border : "transparent"
                                opacity: modelData.enabled ? 1 : 0.35
                                Label { anchors.centerIn: parent; text: modelData.label; color: win.pal.accent; font.pixelSize: 11 }
                                MouseArea {
                                    id: arrowArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: modelData.enabled
                                    onClicked: modelData.action()
                                }
                            }
                        }
                    }

                    // Breadcrumb
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        color: win.pal.content
                        border.color: win.pal.border
                        radius: 3
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 2
                            Repeater {
                                model: win.pathToCurrent
                                delegate: RowLayout {
                                    spacing: 2
                                    Label {
                                        visible: index > 0
                                        text: "›"
                                        color: win.pal.muted
                                    }
                                    Rectangle {
                                        Layout.preferredHeight: 20
                                        color: crumbArea.containsMouse ? win.pal.cmdHover : "transparent"
                                        radius: 2
                                        implicitWidth: crumbLabel.implicitWidth + 12
                                        Label {
                                            id: crumbLabel
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            color: crumbArea.containsMouse ? win.pal.accent : win.pal.text
                                            font.pixelSize: 12
                                        }
                                        MouseArea {
                                            id: crumbArea
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

                    // Search
                    Rectangle {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 26
                        color: win.pal.content
                        border.color: searchField.activeFocus ? win.pal.accent : win.pal.border
                        radius: 3
                        TextField {
                            id: searchField
                            anchors.fill: parent
                            anchors.rightMargin: 24
                            placeholderText: win.currentNode ? ("Buscar en " + win.currentNode.name) : "Buscar"
                            background: Item {}
                            color: win.pal.text
                            font.pixelSize: 12
                            onTextChanged: win.searchQuery = text
                        }
                        Label {
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "🔍"; color: win.pal.muted; font.pixelSize: 11
                        }
                    }
                }
            }

            // ---------- COMMAND BAR ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                color: win.pal.toolbar
                border.color: win.pal.borderSoft

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2

                    Repeater {
                        model: [
                            { label: "Organizar ▾", always: true, action: function(){} },
                            { sep: true },
                            { label: "Abrir ▾", requireSel: true, action: function(){} },
                            { label: "Compartir con", requireSel: true, action: function(){ win.handleCopy() } },
                            { label: "Eliminar", requireSel: true, action: function(){ win.handleDelete() } },
                            { label: "Nueva carpeta", always: true, action: function(){ win.handleNewFolder() } }
                        ]
                        delegate: Loader {
                            sourceComponent: modelData.sep ? sepComp : btnComp
                            Component { id: sepComp
                                Rectangle { implicitWidth: 1; implicitHeight: 18; color: win.pal.border }
                            }
                            Component { id: btnComp
                                Rectangle {
                                    implicitWidth: btnLbl.implicitWidth + 20
                                    implicitHeight: 26
                                    property bool isEnabled: modelData.always || win.selectedCount > 0
                                    color: btnHover.containsMouse && isEnabled ? win.pal.cmdHover : "transparent"
                                    border.color: btnHover.containsMouse && isEnabled ? win.pal.border : "transparent"
                                    radius: 2
                                    opacity: isEnabled ? 1 : 0.45
                                    Label {
                                        id: btnLbl
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: win.pal.text
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: btnHover
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

                    // View switcher
                    ComboBox {
                        id: viewCombo
                        Layout.preferredWidth: 140
                        model: [
                            { text: "Iconos grandes", val: "large" },
                            { text: "Iconos medianos", val: "medium" },
                            { text: "Lista", val: "list" },
                            { text: "Detalles", val: "details" },
                            { text: "Contenido", val: "content" }
                        ]
                        textRole: "text"
                        currentIndex: 0
                        onActivated: win.viewMode = model[currentIndex].val
                    }

                    // Preview toggle
                    Rectangle {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 26
                        color: win.showPreview ? win.pal.cmdHover : (prevHover.containsMouse ? win.pal.cmdHover : "transparent")
                        border.color: win.showPreview ? win.pal.border : "transparent"
                        radius: 2
                        Label { anchors.centerIn: parent; text: "▭"; color: win.pal.text; font.pixelSize: 14 }
                        MouseArea { id: prevHover; anchors.fill: parent; hoverEnabled: true; onClicked: win.showPreview = !win.showPreview }
                    }
                }
            }

            // ---------- BODY ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // SIDEBAR
                Rectangle {
                    visible: win.showSidebar
                    Layout.preferredWidth: 200
                    Layout.fillHeight: true
                    color: win.pal.sidebar
                    border.color: win.pal.borderSoft

                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        Column {
                            width: 200
                            spacing: 2
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

                // MAIN
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

                // PREVIEW
                Rectangle {
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
                        spacing: 12

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            Image {
                                visible: parent.parent.parent.previewItem !== null
                                anchors.centerIn: parent
                                width: 96; height: 96
                                fillMode: Image.PreserveAspectFit
                                source: parent.parent.parent.previewItem ? fs.iconFor(parent.parent.parent.previewItem) : ""
                            }
                            Label {
                                visible: parent.parent.parent.previewItem === null
                                anchors.centerIn: parent
                                text: "Selecciona un archivo\npara previsualizar"
                                color: win.pal.muted
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 12
                            }
                        }

                        Label {
                            visible: parent.parent.previewItem !== null
                            Layout.fillWidth: true
                            text: parent.parent.previewItem ? parent.parent.previewItem.name : ""
                            color: win.pal.text
                            font.pixelSize: 12; font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }
                        Label {
                            visible: parent.parent.previewItem !== null
                            Layout.fillWidth: true
                            text: parent.parent.previewItem ? fs.typeLabel(parent.parent.previewItem) : ""
                            color: win.pal.muted
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ---------- STATUS BAR ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: win.selectedCount === 1 ? 60 : 28
                color: win.pal.status
                border.color: win.pal.borderSoft

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 12

                    Label {
                        visible: win.selectedCount === 0
                        text: win.items.length + " elemento" + (win.items.length === 1 ? "" : "s")
                        color: win.pal.muted
                        font.pixelSize: 11
                    }
                    Label {
                        visible: win.selectedCount > 1
                        text: win.selectedCount + " elementos seleccionados"
                        color: win.pal.muted
                        font.pixelSize: 11
                    }

                    // Detalle de un único seleccionado
                    Image {
                        visible: win.selectedCount === 1
                        source: {
                            if (win.selectedCount !== 1) return ""
                            var id = Object.keys(win.selectedIds)[0]
                            var it = win.items.find(function(i){ return i.id === id })
                            return it ? fs.iconFor(it) : ""
                        }
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36
                        fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                        visible: win.selectedCount === 1
                        Layout.fillWidth: true
                        spacing: 2
                        property var item: {
                            if (win.selectedCount !== 1) return null
                            var id = Object.keys(win.selectedIds)[0]
                            return win.items.find(function(i){ return i.id === id }) || null
                        }
                        Label {
                            text: parent.item ? parent.item.name : ""
                            color: win.pal.text; font.pixelSize: 12; font.bold: true
                        }
                        Label {
                            text: {
                                var it = parent.item; if (!it) return ""
                                var parts = [fs.typeLabel(it)]
                                if (it.modified) parts.push("Modificado: " + it.modified)
                                if (it.size) parts.push("Tamaño: " + it.size)
                                return parts.join("  ·  ")
                            }
                            color: win.pal.muted; font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }

    // ---------- MENÚ CONTEXTUAL ----------
    Menu {
        id: ctxMenu
        property var targetItem: null
        MenuItem { text: "Abrir"; enabled: ctxMenu.targetItem !== null; onTriggered: win.doubleClickItem(ctxMenu.targetItem) }
        MenuSeparator {}
        MenuItem { text: "Copiar\tCtrl+C"; enabled: win.selectedCount > 0; onTriggered: win.handleCopy() }
        MenuItem { text: "Eliminar\tSupr"; enabled: win.selectedCount > 0; onTriggered: win.handleDelete() }
        MenuItem { text: "Cambiar nombre"; enabled: ctxMenu.targetItem !== null }
        MenuSeparator {}
        MenuItem { text: "Nueva carpeta"; onTriggered: win.handleNewFolder() }
        MenuSeparator {}
        MenuItem { text: "Propiedades" }
    }

    // ---------- TOAST ----------
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

    // ---------- VISTAS ----------

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
            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                color: win.pal.toolbar
                border.color: win.pal.border
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
                            color: colHover.containsMouse ? win.pal.cmdHover : "transparent"
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
                            MouseArea { id: colHover; anchors.fill: parent; hoverEnabled: true; onClicked: win.setSort(modelData.id) }
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
                            Layout.leftMargin: 8
                            spacing: 6
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
                color: win.isSelected(modelData.id) ? win.pal.selection : (cvHover.containsMouse ? win.pal.accentSoft : "transparent")
                border.color: win.pal.borderSoft
                border.width: 0
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
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
                MouseArea {
                    id: cvHover
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
                                                    gradient: Gradient { GradientStop { position: 0; color: "#4fd1e8" } GradientStop { position: 1; color: "#1a8ab8" } }
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
