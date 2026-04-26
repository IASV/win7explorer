import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "styles/Palettes.js" as Palettes
import "components"
import "menus"
import "views"

ApplicationWindow {
    id: win
    width: 980
    height: 640
    minimumWidth: 680
    minimumHeight: 440
    visible: true

    // ── Theme ──────────────────────────────────────────────────────────────
    property string themeName: "glass"
    readonly property var pal: Palettes.all[themeName]
    color: pal.bg1

    title: {
        if (isRealPath && fsBackend.pathSegments.length > 0)
            return fsBackend.pathSegments[fsBackend.pathSegments.length - 1].name + " — Win7 Explorer"
        if (currentNode) return currentNode.name + " — Win7 Explorer"
        return "Win7 Explorer"
    }

    // ── Mock filesystem ────────────────────────────────────────────────────
    FileSystem { id: fs }

    // ── Navigation state ───────────────────────────────────────────────────
    property string currentId: "lib-docs"
    property var    historyStack:   [currentId]
    property int    historyIndex:   0

    readonly property bool isRealPath: currentId.startsWith("/")
    readonly property var  currentNode: isRealPath ? null : fs.findNode(currentId)
    readonly property var  pathToCurrent: {
        if (isRealPath) {
            var segs = fsBackend.pathSegments
            var result = []
            for (var i = 0; i < segs.length; i++)
                result.push({ name: segs[i].name, path: segs[i].path, id: segs[i].path })
            return result
        }
        if (!currentNode) return []
        return fs.pathTo(currentId).map(function(n){ return { name: n.name, id: n.id, path: n.id } })
    }

    property var  realFiles:    []
    property var  selectedIds:  ({})
    property int  selectedCount: Object.keys(selectedIds).length
    readonly property var selectedItem: {
        var keys = Object.keys(selectedIds)
        if (keys.length !== 1) return null
        var id = keys[0]
        for (var i = 0; i < items.length; i++)
            if (items[i].id === id) return items[i]
        return null
    }

    // ── View options ───────────────────────────────────────────────────────
    property string viewMode:         "large"
    property string sortBy:           "name"
    property string sortDir:          "asc"
    property bool   showMenuBar:      false
    property bool   showSidebar:      true
    property bool   showPreview:      false
    property bool   showDetailsPanel: false
    property int    sidebarWidth:     220
    property int    previewWidth:     260

    // ── Toast ──────────────────────────────────────────────────────────────
    property string toastMsg: ""
    function showToast(msg) {
        toastMsg = msg
        toastTimer.restart()
    }
    Timer { id: toastTimer; interval: 2800; onTriggered: win.toastMsg = "" }

    // ── fsBackend sync ─────────────────────────────────────────────────────
    Connections {
        target: fsBackend
        function onCurrentFilesChanged() {
            var raw = fsBackend.currentFiles
            var arr = []
            for (var i = 0; i < raw.length; i++) {
                var f = raw[i]
                arr.push({
                    id:       f.path,
                    name:     f.name,
                    type:     f.isDir ? "folder" : "file",
                    ext:      f.ext || "",
                    size:     f.size || "",
                    modified: f.modified || "",
                    iconSrc:  f.iconSrc  || "qrc:/icons/file-generic.png",
                    typeStr:  f.typeStr  || f.mimeType || ""
                })
            }
            win.realFiles = arr
            win.selectedIds = ({})
        }
        function onErrorOccurred(msg) { win.showToast(msg) }
    }

    onCurrentIdChanged: {
        if (isRealPath) fsBackend.navigateTo(currentId)
    }

    // ── Computed item list ─────────────────────────────────────────────────
    readonly property var items: {
        var raw = isRealPath ? realFiles : (currentNode ? (currentNode.children || []) : [])
        var arr = raw.slice()

        // Attach iconSrc / typeStr to mock items
        if (!isRealPath) {
            arr.forEach(function(item) {
                if (!item.iconSrc) item.iconSrc = fs.iconFor(item)
                if (!item.typeStr) item.typeStr  = fs.typeLabel(item)
            })
        }

        // Sort
        arr.sort(function(a, b) {
            // Folders first
            var af = (a.type === "folder") ? 0 : 1
            var bf = (b.type === "folder") ? 0 : 1
            if (af !== bf) return af - bf
            var av, bv
            if (sortBy === "name")     { av = (a.name     || "").toLowerCase(); bv = (b.name     || "").toLowerCase() }
            else if (sortBy === "modified") { av = a.modified || ""; bv = b.modified || "" }
            else if (sortBy === "type")     { av = a.typeStr  || ""; bv = b.typeStr  || "" }
            else if (sortBy === "size")     { av = a.size     || ""; bv = b.size     || "" }
            else                            { av = (a.name || "").toLowerCase(); bv = (b.name || "").toLowerCase() }
            var cmp = av < bv ? -1 : av > bv ? 1 : 0
            return sortDir === "asc" ? cmp : -cmp
        })
        return arr
    }

    // ── Grouped view (Equipo / Red) ────────────────────────────────────────
    readonly property bool useGroupedView: {
        if (isRealPath) return false
        var n = currentNode
        return n !== null && n.type === "group" && (n.kind === "computer" || n.kind === "network")
    }

    readonly property var groupedItems: {
        if (!useGroupedView) return []
        var n = currentNode
        var arr = []
        if (n.kind === "computer") {
            // Combine drives + network locations — mirrors Windows 7 "Equipo"
            var netNode = fs.findNode("network")
            arr = (n.children || []).slice()
            if (netNode && netNode.children) arr = arr.concat(netNode.children.slice())
        } else {
            arr = (n.children || []).slice()
        }
        arr.forEach(function(item) {
            if (!item.iconSrc) item.iconSrc = fs.iconFor(item)
            if (!item.typeStr) item.typeStr  = fs.typeLabel(item)
        })
        return arr
    }

    // ── Navigation helpers ─────────────────────────────────────────────────
    function navigate(id) {
        if (id === currentId) return
        historyStack = historyStack.slice(0, historyIndex + 1)
        historyStack.push(id)
        historyIndex = historyStack.length - 1
        currentId = id
        selectedIds = ({})
    }

    function goBack() {
        if (historyIndex > 0) { historyIndex--; currentId = historyStack[historyIndex]; selectedIds = ({}) }
    }
    function goForward() {
        if (historyIndex < historyStack.length - 1) { historyIndex++; currentId = historyStack[historyIndex]; selectedIds = ({}) }
    }
    function goUp() {
        if (isRealPath) {
            var parts = currentId.split("/").filter(function(p){ return p !== "" })
            if (parts.length === 0) return
            parts.pop()
            navigate(parts.length === 0 ? "/" : "/" + parts.join("/"))
        } else {
            var path = fs.pathTo(currentId)
            if (path && path.length >= 2) navigate(path[path.length - 2].id)
        }
    }

    readonly property bool canGoBack:    historyIndex > 0
    readonly property bool canGoForward: historyIndex < historyStack.length - 1
    readonly property bool canGoUp: {
        if (isRealPath) return currentId !== "/"
        var node = currentNode
        return node ? node.id !== "root" : false
    }

    // ── Selection helpers ──────────────────────────────────────────────────
    function toggleSelect(item, ctrl, shift) {
        if (ctrl) {
            var copy = Object.assign({}, selectedIds)
            if (copy[item.id]) delete copy[item.id]; else copy[item.id] = true
            selectedIds = copy
        } else {
            selectedIds = {}
            var s = {}; s[item.id] = true; selectedIds = s
        }
    }

    function selectAll() {
        var s = {}
        for (var i = 0; i < items.length; i++) s[items[i].id] = true
        selectedIds = s
    }

    function invertSelection() {
        var s = {}
        for (var i = 0; i < items.length; i++)
            if (!selectedIds[items[i].id]) s[items[i].id] = true
        selectedIds = s
    }

    // ── File operations ────────────────────────────────────────────────────
    property string clipboardPath: ""
    property string clipboardMode: ""

    function handleOpen(item) {
        if (item.type === "folder" || item.type === "drive") navigate(item.id)
        else if (isRealPath) Qt.openUrlExternally("file://" + item.id)
    }

    function handleDelete() {
        var keys = Object.keys(selectedIds)
        if (keys.length === 0) return
        if (isRealPath) {
            for (var i = 0; i < keys.length; i++) fsBackend.removeItem(keys[i])
            fsBackend.refresh()
        } else {
            showToast("Eliminar: solo disponible en modo sistema de archivos real")
        }
    }

    function handleNewFolder() {
        if (isRealPath) {
            fsBackend.createFolder(currentId, "Nueva carpeta")
            fsBackend.refresh()
        } else {
            showToast("Nueva carpeta: solo disponible en modo sistema de archivos real")
        }
    }

    function handlePaste() {
        if (!clipboardPath || !isRealPath) { showToast("No hay nada que pegar"); return }
        var dest = currentId + "/" + clipboardPath.split("/").pop()
        if (clipboardMode === "cut") { fsBackend.moveItem(clipboardPath, dest); clipboardPath = "" }
        else fsBackend.copyItem(clipboardPath, dest)
        fsBackend.refresh()
    }

    // ── Keyboard shortcuts ─────────────────────────────────────────────────
    Shortcut { sequence: "F5";          onActivated: { if (isRealPath) fsBackend.refresh() } }
    Shortcut { sequence: "F10";         onActivated: win.showMenuBar = !win.showMenuBar }
    Shortcut { sequence: "Alt+Left";    onActivated: win.goBack() }
    Shortcut { sequence: "Alt+Right";   onActivated: win.goForward() }
    Shortcut { sequence: "Alt+Up";      onActivated: win.goUp() }
    Shortcut { sequence: "Ctrl+A";      onActivated: win.selectAll() }
    Shortcut { sequence: "Delete";      onActivated: win.handleDelete() }
    Shortcut { sequence: "Ctrl+C";      onActivated: { if (selectedItem) { clipboardPath = selectedItem.id; clipboardMode = "copy" } } }
    Shortcut { sequence: "Ctrl+X";      onActivated: { if (selectedItem) { clipboardPath = selectedItem.id; clipboardMode = "cut"  } } }
    Shortcut { sequence: "Ctrl+V";      onActivated: win.handlePaste() }

    // ── Menus ──────────────────────────────────────────────────────────────
    OrganizeMenu {
        id: organizeMenu
        pal:             win.pal
        selectedCount:   win.selectedCount
        showMenuBar:     win.showMenuBar
        showDetailsPanel:win.showDetailsPanel
        showPreview:     win.showPreview
        showSidebar:     win.showSidebar
        onCutRequested:         { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "cut"  } }
        onCopyRequested:        { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "copy" } }
        onPasteRequested:       win.handlePaste()
        onSelectAllRequested:   win.selectAll()
        onMenuBarToggled:       win.showMenuBar      = !win.showMenuBar
        onDetailsPanelToggled:  win.showDetailsPanel = !win.showDetailsPanel
        onPreviewToggled:       win.showPreview      = !win.showPreview
        onSidebarToggled:       win.showSidebar      = !win.showSidebar
        onDeleteRequested:      win.handleDelete()
        onPropertiesRequested:  win.showToast("Propiedades: " + (win.selectedItem ? win.selectedItem.name : ""))
        onCloseRequested:       Qt.quit()
    }

    MenuBarMenus {
        id: mbMenus
        pal:             win.pal
        selectedCount:   win.selectedCount
        viewMode:        win.viewMode
        showMenuBar:     win.showMenuBar
        showDetailsPanel:win.showDetailsPanel
        showPreview:     win.showPreview
        showSidebar:     win.showSidebar
        themeName:       win.themeName
        onNewFolderRequested:        win.handleNewFolder()
        onDeleteRequested:           win.handleDelete()
        onRenameRequested:           win.showToast("Cambiar nombre: selecciona un archivo")
        onPropertiesRequested:       win.showToast("Propiedades")
        onCloseRequested:            Qt.quit()
        onCutRequested:              { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "cut"  } }
        onCopyRequested:             { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "copy" } }
        onPasteRequested:            win.handlePaste()
        onSelectAllRequested:        win.selectAll()
        onInvertSelectionRequested:  win.invertSelection()
        onViewModeChangeRequested:   function(m) { win.viewMode = m }
        onSortRequested:             function(col) { if (win.sortBy === col) win.sortDir = (win.sortDir === "asc" ? "desc" : "asc"); else { win.sortBy = col; win.sortDir = "asc" } }
        onMenuBarToggled:            win.showMenuBar      = !win.showMenuBar
        onDetailsPanelToggled:       win.showDetailsPanel = !win.showDetailsPanel
        onPreviewToggled:            win.showPreview      = !win.showPreview
        onSidebarToggled:            win.showSidebar      = !win.showSidebar
        onRefreshRequested:          { if (win.isRealPath) fsBackend.refresh() }
        onThemeChangeRequested:      function(t) { win.themeName = t }
        onTerminalRequested:         win.showToast("Abriendo terminal…")
        onHelpRequested:             win.showToast("Ayuda no disponible")
        onAboutRequested:            aboutDialog.open()
    }

    ContextMenu {
        id: ctxMenu
        pal:          win.pal
        selectedCount: win.selectedCount
        onOpenRequested:       function(item) { win.handleOpen(item) }
        onCutRequested:        { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "cut"  } }
        onCopyRequested:       { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "copy" } }
        onPasteRequested:      win.handlePaste()
        onDeleteRequested:     win.handleDelete()
        onRenameRequested:     win.showToast("Cambiar nombre: " + (win.selectedItem ? win.selectedItem.name : ""))
        onPropertiesRequested: win.showToast("Propiedades: " + (win.selectedItem ? win.selectedItem.name : ""))
        onNewFolderRequested:  win.handleNewFolder()
    }

    // ── About dialog ───────────────────────────────────────────────────────
    Dialog {
        id: aboutDialog
        title: "Acerca de Win7 Explorer"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok
        Label {
            text: "Win7 Explorer\nRéplica de Windows 7 File Explorer para Linux\nDesarrollado con Qt6 / QML"
            color: win.pal.text; font.pixelSize: 13
        }
    }

    // ── View components ────────────────────────────────────────────────────
    Component {
        id: emptyComp
        Item {
            Column {
                anchors.centerIn: parent; spacing: 12
                Canvas {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 64; height: 64
                    property color fg: win.pal.muted
                    onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,64,64)
                        ctx.strokeStyle=fg; ctx.globalAlpha=0.3; ctx.lineWidth=1.5
                        ctx.strokeRect(12,10,40,44)
                        ctx.beginPath(); ctx.moveTo(20,24); ctx.lineTo(44,24)
                        ctx.moveTo(20,32); ctx.lineTo(44,32); ctx.moveTo(20,40); ctx.lineTo(36,40); ctx.stroke()
                    }
                }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Esta carpeta está vacía"; color: win.pal.muted; font.pixelSize: 13 }
            }
        }
    }

    Component {
        id: iconsComp
        IconsView {
            pal: win.pal
            model: win.items
            selectedIds: win.selectedIds
            viewMode: win.viewMode
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                ctxMenu.targetItem = item; ctxMenu.popup()
            }
        }
    }

    Component {
        id: listComp
        FileListView {
            pal: win.pal
            model: win.items
            selectedIds: win.selectedIds
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                ctxMenu.targetItem = item; ctxMenu.popup()
            }
        }
    }

    Component {
        id: detailsComp
        DetailsView {
            pal: win.pal
            model: win.items
            selectedIds: win.selectedIds
            sortBy: win.sortBy
            sortDir: win.sortDir
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                ctxMenu.targetItem = item; ctxMenu.popup()
            }
            onSortRequested: function(col) {
                if (win.sortBy === col) win.sortDir = (win.sortDir === "asc" ? "desc" : "asc")
                else { win.sortBy = col; win.sortDir = "asc" }
            }
        }
    }

    Component {
        id: contentComp
        ContentView {
            pal: win.pal
            model: win.items
            selectedIds: win.selectedIds
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                ctxMenu.targetItem = item; ctxMenu.popup()
            }
        }
    }

    Component {
        id: groupedComp
        GroupedView {
            pal: win.pal
            model: win.groupedItems
            selectedIds: win.selectedIds
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                ctxMenu.targetItem = item; ctxMenu.popup()
            }
        }
    }

    // ── Layout ─────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Address bar
        AddressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            pal:           win.pal
            canGoBack:     win.canGoBack
            canGoForward:  win.canGoForward
            canGoUp:       win.canGoUp
            pathToCurrent: win.pathToCurrent
            onBackRequested:    win.goBack()
            onForwardRequested: win.goForward()
            onUpRequested:      win.goUp()
            onSegmentClicked:   function(id) { win.navigate(id) }
            onSearchChanged:    function(text) { /* TODO: filter */ }
        }

        // Menu bar (F10 toggle)
        WinMenuBar {
            Layout.fillWidth: true
            Layout.preferredHeight: win.showMenuBar ? 26 : 0
            Layout.maximumHeight:   win.showMenuBar ? 26 : 0
            clip: true
            visible: win.showMenuBar
            pal: win.pal
            onArchivoClicked:     mbMenus.archivoMenu.popup()
            onEdicionClicked:     mbMenus.edicionMenu.popup()
            onVerClicked:         mbMenus.verMenu.popup()
            onHerramientasClicked:mbMenus.herramientasMenu.popup()
            onAyudaClicked:       mbMenus.ayudaMenu.popup()
        }

        // Command bar
        CommandBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            pal:           win.pal
            selectedCount: win.selectedCount
            showPreview:   win.showPreview
            viewMode:      win.viewMode
            onOrganizeClicked:          organizeMenu.popup()
            onDeleteRequested:          win.handleDelete()
            onNewFolderRequested:       win.handleNewFolder()
            onPreviewToggled:           win.showPreview = !win.showPreview
            onViewModeChangeRequested:  function(m) { win.viewMode = m }
        }

        // Separator
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.pal.borderSoft }

        // Body: sidebar + content + preview
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Sidebar / navigation panel
            NavigationPanel {
                Layout.preferredWidth: win.showSidebar ? win.sidebarWidth : 0
                Layout.maximumWidth:   win.showSidebar ? 400 : 0
                Layout.minimumWidth:   0
                Layout.fillHeight: true
                clip: true
                pal: win.pal
                currentPath: win.currentId
                onFolderActivated: function(path) { win.navigate(path) }
            }

            // Sidebar splitter
            Rectangle {
                Layout.preferredWidth: win.showSidebar ? 4 : 0
                Layout.maximumWidth:   win.showSidebar ? 4 : 0
                Layout.fillHeight: true
                color: win.pal.borderSoft
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.SplitHCursor
                    property int startX: 0; property int startW: 0
                    onPressed:         function(mouse) { startX = mouse.x; startW = win.sidebarWidth }
                    onPositionChanged: function(mouse) { if (pressed) win.sidebarWidth = Math.max(150, Math.min(400, startW + (mouse.x - startX))) }
                }
            }

            // Main content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: win.pal.content

                Loader {
                    id: viewLoader
                    anchors.fill: parent
                    sourceComponent: {
                        if (win.useGroupedView)        return groupedComp
                        if (win.items.length === 0)    return emptyComp
                        if (win.viewMode === "large" || win.viewMode === "medium") return iconsComp
                        if (win.viewMode === "list")    return listComp
                        if (win.viewMode === "details") return detailsComp
                        if (win.viewMode === "content") return contentComp
                        return iconsComp
                    }
                }

                // Empty-area right-click
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    propagateComposedEvents: true
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            ctxMenu.targetItem = null
                            ctxMenu.popup()
                        }
                    }
                }
            }

            // Preview splitter
            Rectangle {
                Layout.preferredWidth: win.showPreview ? 4 : 0
                Layout.maximumWidth:   win.showPreview ? 4 : 0
                Layout.fillHeight: true
                color: win.pal.borderSoft
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.SplitHCursor
                    property int startX: 0; property int startW: 0
                    onPressed:         function(mouse) { startX = mouse.x; startW = win.previewWidth }
                    onPositionChanged: function(mouse) { if (pressed) win.previewWidth = Math.max(180, Math.min(500, startW - (mouse.x - startX))) }
                }
            }

            // Preview panel
            PreviewPanel {
                Layout.preferredWidth: win.showPreview ? win.previewWidth : 0
                Layout.maximumWidth:   win.showPreview ? 500 : 0
                Layout.minimumWidth:   0
                Layout.fillHeight: true
                clip: true
                pal: win.pal
                previewItem: win.selectedItem
            }
        }

        // Details panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: win.showDetailsPanel ? 1 : 0
            Layout.maximumHeight:   win.showDetailsPanel ? 1 : 0
            color: win.pal.borderSoft
        }
        DetailsPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: win.showDetailsPanel ? 72 : 0
            Layout.maximumHeight:   win.showDetailsPanel ? 72 : 0
            clip: true
            pal: win.pal
            detailItem: win.selectedItem
        }

        // Status bar
        StatusBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            pal:           win.pal
            itemCount:     win.items.length
            selectedCount: win.selectedCount
            selItem:       win.selectedItem
        }
    }

    // Toast notification
    ToastNotification {
        pal:     win.pal
        message: win.toastMsg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        z: 200
    }
}
