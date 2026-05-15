import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import "styles/Palettes.js" as Palettes
import "components"
import "views"

ApplicationWindow {
    id: win
    width: 980
    height: 640
    minimumWidth: 680
    minimumHeight: 440
    visible: true

    // ── Persistent settings ────────────────────────────────────────────────
    property bool _settingsReady: false

    Settings {
        id: appSettings
        property alias viewMode:            win.viewMode
        property alias sortBy:              win.sortBy
        property alias sortDir:             win.sortDir
        property alias showMenuBar:         win.showMenuBar
        property alias showSidebar:         win.showSidebar
        property alias showPreview:         win.showPreview
        property alias showDetailsPanel:    win.showDetailsPanel
        property alias showStatusBar:       win.showStatusBar
        property alias showContentPreviews: win.showContentPreviews
        property alias themeName:           win.themeName
        property alias deleteToTrash:       win.deleteToTrash
        property alias showHiddenFiles:     win.showHiddenFiles
        property alias sidebarWidth:        win.sidebarWidth
        property alias previewWidth:        win.previewWidth
        property alias windowWidth:         win.width
        property alias windowHeight:        win.height
        property string favoritesJson:      ""

        Component.onCompleted: {
            if (favoritesJson !== "") {
                try { win.favorites = JSON.parse(favoritesJson) } catch(e) {}
            }
            win._settingsReady = true
        }
    }

    // Incremented every time FsBackend reports a device change, forcing
    // groupedItems (which calls plain functions) to re-evaluate.
    property int _devicesVersion: 0

    // ── Preferences ───────────────────────────────────────────────────────
    property bool deleteToTrash:   true
    property bool showHiddenFiles: false
    onShowHiddenFilesChanged: FsBackend.showHiddenFiles = showHiddenFiles

    // ── Theme ──────────────────────────────────────────────────────────────
    property string themeName: "glass"
    readonly property var pal: Palettes.all[themeName]
    color: pal.bg1

    title: {
        var _l = I18n.lang
        if (currentId === "libraries") return I18n.t("Bibliotecas — Win7 Explorer")
        if (isRealPath && FsBackend.pathSegments.length > 0)
            return FsBackend.pathSegments[FsBackend.pathSegments.length - 1].name + " — Win7 Explorer"
        if (currentNode) return currentNode.name + " — Win7 Explorer"
        return "Win7 Explorer"
    }

    // ── Mock filesystem ────────────────────────────────────────────────────
    FileSystem { id: fs }

    // ── Navigation state ───────────────────────────────────────────────────
    property string currentId: "computer"
    property var    historyStack:   [currentId]
    property int    historyIndex:   0

    // ── Favorites ──────────────────────────────────────────────────────────
    property var favorites: [
        { name: (I18n.lang, I18n.t("Escritorio")), path: FsBackend.desktopPath(),   icon: "folder-closed" },
        { name: (I18n.lang, I18n.t("Descargas")),  path: FsBackend.downloadsPath(), icon: "folder-blue" }
    ]
    onFavoritesChanged: if (win._settingsReady) appSettings.favoritesJson = JSON.stringify(favorites)

    function addToFavorites(item) {
        if (!item || item.type !== "folder") return
        for (var i = 0; i < favorites.length; i++)
            if (favorites[i].path === item.id) { showToast(I18n.t("Ya está en Favoritos")); return }
        var copy = favorites.slice()
        copy.push({ name: item.name, path: item.id, icon: "folder-closed" })
        favorites = copy
        showToast("'" + item.name + "' " + I18n.t("agregado a Favoritos"))
    }

    readonly property bool isRealPath: currentId.startsWith("/")
    readonly property var  currentNode: isRealPath ? null : fs.findNode(currentId)
    readonly property var  pathToCurrent: {
        if (currentId === "libraries")
            return [{ name: (I18n.lang, I18n.t("Bibliotecas")), id: "libraries", path: "libraries" }]
        if (currentId === "trash")
            return [{ name: (I18n.lang, I18n.t("Papelera de reciclaje")), id: "trash", path: "trash" }]
        if (isRealPath) {
            var segs = FsBackend.pathSegments
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
        var pool = useGroupedView ? groupedItems : items
        for (var i = 0; i < pool.length; i++)
            if (pool[i].id === id) return pool[i]
        return null
    }

    // ── Special-path detection ─────────────────────────────────────────────
    function specialFolderIcon(path) {
        if (path === FsBackend.documentsPath()) return "document"
        if (path === FsBackend.musicPath())     return "music"
        if (path === FsBackend.picturesPath())  return "picture"
        if (path === FsBackend.videosPath())    return "video"
        if (path === FsBackend.downloadsPath()) return "folder-blue"
        return null
    }

    readonly property bool isSpecialPath: {
        if (!isRealPath)
            return currentId === "trash" || currentId === "network" || currentId === "libraries"
        return currentId === FsBackend.homePath()      ||
               currentId === FsBackend.desktopPath()   ||
               currentId === FsBackend.documentsPath() ||
               currentId === FsBackend.musicPath()     ||
               currentId === FsBackend.picturesPath()  ||
               currentId === FsBackend.videosPath()    ||
               currentId === FsBackend.downloadsPath()
    }

    readonly property string currentFolderIconSrc: {
        if (!isRealPath) {
            if (currentId === "trash")     return "image://fileicons/user-trash"
            if (currentId === "network")   return "image://fileicons/network-workgroup"
            if (currentId === "libraries") return "image://fileicons/libraries"
            return "image://fileicons/folder-closed"
        }
        var si = specialFolderIcon(currentId)
        return "image://fileicons/" + (si || "folder-closed")
    }

    readonly property string currentFolderName: {
        var _l = I18n.lang
        if (currentId === "libraries") return I18n.t("Bibliotecas")
        if (currentId === "trash")     return I18n.t("Papelera de reciclaje")
        if (isRealPath && FsBackend.pathSegments.length > 0)
            return FsBackend.pathSegments[FsBackend.pathSegments.length - 1].name
        if (currentNode) return currentNode.name
        return ""
    }
    readonly property int currentItemCount: useGroupedView ? groupedItems.length : items.length

    readonly property string totalSelectedSizeStr: {
        if (selectedCount <= 1) return ""
        var pool = useGroupedView ? groupedItems : items
        var totalBytes = 0
        for (var i = 0; i < pool.length; i++)
            if (selectedIds[pool[i].id]) totalBytes += (pool[i].sizeBytes || 0)
        return totalBytes > 0 ? FsBackend.formatFileSize(totalBytes) : ""
    }

    readonly property string selectedItemType: {
        var item = selectedItem
        if (!item) return "none"
        if (item.type === "folder") return "folder"
        if (item.type === "drive")  return "drive"
        if (item.type === "file") {
            var ts = (item.typeStr || "").toLowerCase()
            if (ts.indexOf("image") >= 0) return "image"
            if (ts.indexOf("audio") >= 0 || ts.indexOf("música") >= 0 || ts.indexOf("musica") >= 0) return "audio"
            if (ts.indexOf("video") >= 0 || ts.indexOf("vídeo") >= 0) return "video"
            if (ts.indexOf("document") >= 0 || ts.indexOf("texto") >= 0 || ts.indexOf("pdf") >= 0 ||
                ts.indexOf("officedocument") >= 0 || ts.indexOf("word") >= 0 ||
                ts.indexOf("spreadsheet") >= 0 || ts.indexOf("text/") >= 0) return "document"
        }
        return "generic"
    }

    // ── View options ───────────────────────────────────────────────────────
    property string viewMode:            "large"
    property string sortBy:              "name"
    property string sortDir:             "asc"
    property string groupBy:             "none"
    property bool   showMenuBar:         false
    property bool   showSidebar:         true
    property bool   showPreview:         false
    property bool   showDetailsPanel:    true
    property bool   showStatusBar:       true
    property bool   showContentPreviews: true
    property string renamingId:          ""
    property int    sidebarWidth:        220
    property int    previewWidth:        260

    // ── Toast ──────────────────────────────────────────────────────────────
    property string toastMsg: ""
    function showToast(msg) {
        toastMsg = msg
        toastTimer.restart()
    }
    Timer { id: toastTimer; interval: 2800; onTriggered: win.toastMsg = "" }

    // ── FsBackend sync ─────────────────────────────────────────────────────
    Connections {
        target: FsBackend
        function onCurrentFilesChanged() {
            var raw = FsBackend.currentFiles
            var arr = []
            for (var i = 0; i < raw.length; i++) {
                var f = raw[i]
                var isImg = !f.isDir && (f.mimeIcon || "").indexOf("image") >= 0
                var iconName = f.isDir ? (win.specialFolderIcon(f.path) || f.mimeIcon || "folder-closed")
                                       : (f.mimeIcon || "file-generic")
                arr.push({
                    id:         f.path,
                    name:       f.name,
                    type:       f.isDir ? "folder" : "file",
                    size:       f.sizeFormatted || "",
                    sizeBytes:  f.isDir ? 0 : (f.size || 0),
                    modified:   f.modified || "",
                    iconSrc:    "image://fileicons/" + iconName,
                    typeStr:    f.type || "",
                    previewSrc: isImg ? ("image://fileicons/" + encodeURIComponent(f.path)) : "",
                    isHidden:   (f.name || "").startsWith(".")
                })
            }
            win.realFiles = arr
            win.selectedIds = ({})
            if (win.pendingRenameOnRefresh !== "") {
                var pending = win.pendingRenameOnRefresh
                win.pendingRenameOnRefresh = ""
                var s = {}
                s[pending] = true
                win.selectedIds = s
                win.renamingId = pending
            }
        }
        function onErrorOccurred(msg) { win.showToast(msg) }
        function onDevicesChanged() { win._devicesVersion++ }
    }

    onCurrentIdChanged: { /* navigation is driven by navigate/goBack/goForward */ }

    // ── Computed item list ─────────────────────────────────────────────────
    readonly property var items: {
        var raw
        if (currentId === "libraries") {
            var libList = FsBackend.getLibraries()
            raw = []
            for (var li = 0; li < libList.length; li++) {
                var lib = libList[li]
                raw.push({
                    id: lib.path, name: lib.name, type: "folder",
                    size: "", sizeBytes: 0, modified: "",
                    iconSrc:    "image://fileicons/" + lib.icon,
                    typeStr:    I18n.t("Biblioteca"),
                    previewSrc: ""
                })
            }
            return raw
        }
        raw = (isRealPath || currentId === "trash") ? realFiles
            : (currentNode ? (currentNode.children || []) : [])
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
        var _v = _devicesVersion // trigger re-evaluation when devices change
        if (!useGroupedView) return []
        var n = currentNode
        var arr = []
        if (n.kind === "computer") {
            var drives = FsBackend.getStorageDevices()
            for (var i = 0; i < drives.length; i++) {
                var d = drives[i]
                arr.push({
                    id:      d.path,
                    name:    d.displayName,
                    type:    "drive",
                    kind:    d.kind,
                    total:   d.totalGb,
                    free:    d.freeGb,
                    iconSrc: "image://fileicons/drive-" + d.kind,
                    typeStr: d.fsType || I18n.t("Unidad local")
                })
            }
        } else if (n.kind === "network") {
            var netDevs = FsBackend.getNetworkDevices()
            for (var j = 0; j < netDevs.length; j++) {
                var nd = netDevs[j]
                arr.push({
                    id:      nd.path,
                    name:    nd.displayName,
                    type:    "network",
                    kind:    nd.kind,
                    total:   nd.totalGb || 0,
                    free:    nd.freeGb  || 0,
                    iconSrc: "image://fileicons/network",
                    typeStr: nd.kind ? (nd.kind.toUpperCase() + " Share") : I18n.t("Recurso de red")
                })
            }
        }
        return arr
    }

    // ── Navigation helpers ─────────────────────────────────────────────────
    function _syncBackend(id) {
        if (id === "trash")
            FsBackend.navigateTo(FsBackend.homePath() + "/.local/share/Trash/files")
        else if (id.startsWith("/"))
            FsBackend.navigateTo(id)
    }

    function navigate(id) {
        if (id === currentId) return
        realFiles = []
        _syncBackend(id)          // load backend BEFORE currentId changes so pathSegments are ready
        historyStack = historyStack.slice(0, historyIndex + 1)
        historyStack.push(id)
        historyIndex = historyStack.length - 1
        currentId = id
        selectedIds = ({})
    }

    function goBack() {
        if (historyIndex > 0) {
            historyIndex--
            var id = historyStack[historyIndex]
            realFiles = []
            _syncBackend(id)
            currentId = id
            selectedIds = ({})
        }
    }
    function goForward() {
        if (historyIndex < historyStack.length - 1) {
            historyIndex++
            var id = historyStack[historyIndex]
            realFiles = []
            _syncBackend(id)
            currentId = id
            selectedIds = ({})
        }
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
            for (var i = 0; i < keys.length; i++) {
                if (win.deleteToTrash) FsBackend.trashItem(keys[i])
                else                   FsBackend.removeItem(keys[i])
            }
            FsBackend.refresh()
        } else {
            showToast(I18n.t("Eliminar: solo disponible en modo sistema de archivos real"))
        }
    }

    property string pendingRenameOnRefresh: ""

    function handleNewFolder() {
        if (isRealPath) {
            var newFolderName = I18n.t("Nueva carpeta")
            win.pendingRenameOnRefresh = currentId.replace(/\/$/, '') + "/" + newFolderName
            FsBackend.createFolder(currentId, newFolderName)
            // createFolder calls refresh() internally; no need to call again
        } else {
            showToast(I18n.t("Nueva carpeta: solo disponible en modo sistema de archivos real"))
        }
    }

    function handlePaste() {
        if (!clipboardPath || !isRealPath) { showToast(I18n.t("No hay nada que pegar")); return }
        var dest = currentId + "/" + clipboardPath.split("/").pop()
        if (clipboardMode === "cut") { FsBackend.moveItem(clipboardPath, dest); clipboardPath = "" }
        else FsBackend.copyItem(clipboardPath, dest)
        FsBackend.refresh()
    }

    // ── Keyboard shortcuts ─────────────────────────────────────────────────
    Shortcut { sequence: "F2";          onActivated: { if (win.selectedItem && win.isRealPath) win.renamingId = win.selectedItem.id } }
    Shortcut { sequence: "F5";          onActivated: { if (isRealPath) FsBackend.refresh() } }
    Shortcut { sequence: "F10";         onActivated: win.showMenuBar = !win.showMenuBar }
    Shortcut { sequence: "Alt+Return";  onActivated: win.showMenuBar = !win.showMenuBar }
    Shortcut { sequence: "Alt+F10";    onActivated: win.showMenuBar = !win.showMenuBar }
    Shortcut { sequence: "Alt+Left";    onActivated: win.goBack() }
    Shortcut { sequence: "Alt+Right";   onActivated: win.goForward() }
    Shortcut { sequence: "Alt+Up";      onActivated: win.goUp() }
    Shortcut { sequence: "Ctrl+A";      onActivated: win.selectAll() }
    Shortcut { sequence: "Delete";      onActivated: win.handleDelete() }
    Shortcut { sequence: "Ctrl+C";      onActivated: { if (selectedItem) { clipboardPath = selectedItem.id; clipboardMode = "copy" } } }
    Shortcut { sequence: "Ctrl+X";      onActivated: { if (selectedItem) { clipboardPath = selectedItem.id; clipboardMode = "cut"  } } }
    Shortcut { sequence: "Ctrl+V";      onActivated: win.handlePaste() }

    // ── Unified menu action handler ────────────────────────────────────────
    function handleMenuAction(action) {
        if (!action) return
        if (action === "cut")              { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "cut"  }; return }
        if (action === "copy")             { if (win.selectedItem) { win.clipboardPath = win.selectedItem.id; win.clipboardMode = "copy" }; return }
        if (action === "paste")            { win.handlePaste(); return }
        if (action === "delete")           { win.handleDelete(); return }
        if (action === "rename")           { if (win.selectedItem && win.isRealPath) win.renamingId = win.selectedItem.id; return }
        if (action === "restore")          { if (win.selectedItem) FsBackend.restoreFromTrash(win.selectedItem.id); return }
        if (action === "properties")       { if (win.selectedItem) { propertiesDialog.item = win.selectedItem; propertiesDialog.transientParent = win; propertiesDialog.show() }; return }
        if (action === "new-folder")       { win.handleNewFolder(); return }
        if (action.startsWith("new-file:")) {
            if (!win.isRealPath) { win.showToast(I18n.t("Solo disponible en el sistema de archivos real")); return }
            var nfExt = action.substring(9)
            var nfName, nfContent
            if      (nfExt === "txt")   { nfName = I18n.t("Nuevo archivo de texto.txt"); nfContent = "" }
            else if (nfExt === "html")  { nfName = I18n.t("Nuevo documento.html"); nfContent = "<!DOCTYPE html>\n<html>\n<head><title></title></head>\n<body>\n\n</body>\n</html>\n" }
            else                        { nfName = I18n.t("Nuevo archivo"); nfContent = "" }
            FsBackend.createFile(win.currentId, nfName, nfContent)
            return
        }
        if (action === "open")             { win.handleOpen(win.selectedItem); return }
        if (action === "favorites")        { win.addToFavorites(win.selectedItem); return }
        if (action === "extract-here")     { if (win.selectedItem) FsBackend.extractHere(win.selectedItem.id); return }
        if (action === "refresh")          { if (win.isRealPath) FsBackend.refresh(); return }
        if (action === "select-all")       { win.selectAll(); return }
        if (action === "invert-selection") { win.invertSelection(); return }
        if (action === "close")            { Qt.quit(); return }
        if (action === "about")            { aboutDialog.open(); return }
        if (action === "help")             { Qt.openUrlExternally("https://github.com/"); return }
        if (action === "open-window")      { NativeMenu.openNewWindow(win.isRealPath ? win.currentId : ""); return }
        if (action === "terminal")         { NativeMenu.openTerminalAt(win.isRealPath ? win.currentId : ""); return }
        if (action === "connect-drive")    { connectDriveDialog.open(); return }
        if (action === "disconnect-drive") { if (win.selectedItem) { FsBackend.disconnectFromServer(win.selectedItem.id); win.showToast(I18n.t("Desconectando…")) }; return }
        if (action === "folder-options")   { folderOptionsDialog.showHiddenFiles = win.showHiddenFiles; folderOptionsDialog.open(); return }
        if (action === "toggle:hidden")    { win.showHiddenFiles = !win.showHiddenFiles; return }
        if (action === "copy-to-folder")   { folderPickerDialog.operation = "copy"; folderPickerDialog.open(win.isRealPath ? win.currentId : ""); return }
        if (action === "move-to-folder")   { folderPickerDialog.operation = "move"; folderPickerDialog.open(win.isRealPath ? win.currentId : ""); return }
        if (action === "send-to:desktop") {
            if (win.selectedItem) {
                var desktopDest = FsBackend.desktopPath() + "/" + win.selectedItem.name
                FsBackend.createSymlink(win.selectedItem.id, desktopDest)
                win.showToast(I18n.t("Acceso directo creado en el Escritorio"))
            }
            return
        }
        if (action === "send-to:mail") {
            if (win.selectedItem) Qt.openUrlExternally("mailto:?attach=" + encodeURIComponent(win.selectedItem.id))
            return
        }
        if (action === "other-app") {
            if (win.selectedItem) Qt.openUrlExternally("file://" + win.selectedItem.id)
            return
        }
        if (action === "paste-shortcut") {
            if (win.clipboardPath && win.isRealPath) {
                var fn = win.clipboardPath.split("/").pop()
                FsBackend.createSymlink(win.clipboardPath, win.currentId + "/" + fn)
                FsBackend.refresh()
            }
            return
        }
        if (action === "new-shortcut") {
            if (win.selectedItem && win.isRealPath) {
                var shortcutName = win.selectedItem.name + " " + I18n.t("(acceso directo)")
                FsBackend.createSymlink(win.selectedItem.id, win.currentId + "/" + shortcutName)
                FsBackend.refresh()
            }
            return
        }
        if (action.startsWith("view:"))    { win.viewMode = action.substring(5); return }
        if (action.startsWith("sort:"))    { var col = action.substring(5); if (win.sortBy === col) win.sortDir = (win.sortDir === "asc" ? "desc" : "asc"); else { win.sortBy = col; win.sortDir = "asc" }; return }
        if (action.startsWith("sortdir:")) { win.sortDir = action.substring(8); return }
        if (action.startsWith("group:"))   { win.groupBy = action.substring(6); return }
        if (action === "toggle:trash")     { win.deleteToTrash = !win.deleteToTrash; return }
        if (action.startsWith("theme:"))   { win.themeName = action.substring(6); return }
        if (action.startsWith("language:")){ I18n.lang = action.substring(9); return }
        if (action.startsWith("layout:"))  {
            var layout = action.substring(7)
            if (layout === "menu-bar")      { win.showMenuBar      = !win.showMenuBar;      return }
            if (layout === "details-panel") { win.showDetailsPanel = !win.showDetailsPanel; return }
            if (layout === "preview")       { win.showPreview      = !win.showPreview;      return }
            if (layout === "sidebar")       { win.showSidebar      = !win.showSidebar;      return }
            if (layout === "status-bar")       { win.showStatusBar       = !win.showStatusBar;       return }
            if (layout === "content-previews") { win.showContentPreviews = !win.showContentPreviews; return }
        }
    }

    function menuBarParams() {
        return {
            selectedCount:       win.selectedCount,
            viewMode:            win.viewMode,
            sortBy:              win.sortBy,
            sortDir:             win.sortDir,
            showMenuBar:         win.showMenuBar,
            showDetailsPanel:    win.showDetailsPanel,
            showPreview:         win.showPreview,
            showSidebar:         win.showSidebar,
            showStatusBar:       win.showStatusBar,
            showContentPreviews: win.showContentPreviews,
            themeName:           win.themeName,
            language:            I18n.lang,
            deleteToTrash:       win.deleteToTrash
        }
    }

    function showContextMenu(item) {
        var isEmpty = (item === null || item === undefined)
        var action = NativeMenu.showMenu({
            type:          isEmpty ? "empty" : "file",
            item:          isEmpty ? {} : { id: item.id, name: item.name, type: item.type },
            selectedCount: win.selectedCount,
            viewMode:      win.viewMode,
            sortBy:        win.sortBy,
            sortDir:       win.sortDir,
            groupBy:       win.groupBy,
            inTrash:       win.currentId === "trash",
            currentPath:   win.isRealPath ? win.currentId : ""
        })
        if (action === "open" && item) { win.handleOpen(item); return }
        win.handleMenuAction(action)
    }

    // ── Properties dialog ──────────────────────────────────────────────────
    PropertiesDialog {
        id: propertiesDialog
        pal: win.pal
    }

    // ── Rename dialog ──────────────────────────────────────────────────────
    RenameDialog {
        id: renameDialog
        pal: win.pal
        anchors.centerIn: parent
        onRenameConfirmed: function(oldPath, newName) {
            var dir = oldPath.substring(0, oldPath.lastIndexOf('/'))
            var newPath = dir + "/" + newName
            FsBackend.renameItem(oldPath, newPath)
        }
    }

    // ── About dialog ───────────────────────────────────────────────────────
    AboutDialog {
        id: aboutDialog
        pal: win.pal
    }

    // ── Connect drive dialog ───────────────────────────────────────────────
    ConnectDriveDialog {
        id: connectDriveDialog
        pal: win.pal
        onConnectRequested: function(uri) {
            FsBackend.connectToServer(uri)
            win.showToast(I18n.t("Conectando a ") + uri + "…")
        }
    }

    // ── Folder picker dialog ───────────────────────────────────────────────
    FolderPickerDialog {
        id: folderPickerDialog
        pal: win.pal
        onFolderSelected: function(destPath, op) {
            var keys = Object.keys(win.selectedIds)
            if (keys.length === 0) return
            for (var i = 0; i < keys.length; i++) {
                var fn = keys[i].split("/").pop()
                if (op === "move") FsBackend.moveItem(keys[i], destPath + "/" + fn)
                else               FsBackend.copyItem(keys[i], destPath + "/" + fn)
            }
            FsBackend.refresh()
        }
    }

    // ── Folder options dialog ──────────────────────────────────────────────
    FolderOptionsDialog {
        id: folderOptionsDialog
        pal: win.pal
        onOptionsChanged: function(showHidden) {
            win.showHiddenFiles = showHidden
        }
    }

    // ── View components ────────────────────────────────────────────────────
    Component {
        id: networkEmptyComp
        Item {
            Column {
                anchors.centerIn: parent; spacing: 14
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "qrc:/icons/network.png"
                    width: 64; height: 64; opacity: 0.25
                    fillMode: Image.PreserveAspectFit
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (I18n.lang, I18n.t("No se detectaron dispositivos de red"))
                    color: win.pal.muted; font.pixelSize: 13
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (I18n.lang, I18n.t("Comprueba que estés conectado a una red local"))
                    color: win.pal.muted; font.pixelSize: 11; opacity: 0.7
                }
            }
        }
    }

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
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: (I18n.lang, I18n.t("Esta carpeta está vacía")); color: win.pal.muted; font.pixelSize: 13 }
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
            renamingId: win.renamingId
            showContentPreviews: win.showContentPreviews
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                win.showContextMenu(item)
            }
            onEmptyAreaClicked: win.selectedIds = ({})
            onRenameCommitted: function(id, newName) {
                win.renamingId = ""
                var dir = id.substring(0, id.lastIndexOf('/'))
                FsBackend.renameItem(id, dir + "/" + newName)
            }
            onRenameCancelled: win.renamingId = ""
            onItemDroppedOnFolder: function(srcPath, destFolder) {
                var fileName = srcPath.split("/").pop()
                if (fileName) FsBackend.moveItem(srcPath, destFolder + "/" + fileName)
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
                win.showContextMenu(item)
            }
            onEmptyAreaClicked: win.selectedIds = ({})
            onItemDroppedOnFolder: function(srcPath, destFolder) {
                var fileName = srcPath.split("/").pop()
                if (fileName) FsBackend.moveItem(srcPath, destFolder + "/" + fileName)
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
            groupBy: win.groupBy
            renamingId: win.renamingId
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                win.showContextMenu(item)
            }
            onSortRequested: function(col) {
                if (win.sortBy === col) win.sortDir = (win.sortDir === "asc" ? "desc" : "asc")
                else { win.sortBy = col; win.sortDir = "asc" }
            }
            onEmptyAreaClicked: win.selectedIds = ({})
            onRenameCommitted: function(id, newName) {
                win.renamingId = ""
                var dir = id.substring(0, id.lastIndexOf('/'))
                FsBackend.renameItem(id, dir + "/" + newName)
            }
            onRenameCancelled: win.renamingId = ""
            onItemDroppedOnFolder: function(srcPath, destFolder) {
                var fileName = srcPath.split("/").pop()
                if (fileName) FsBackend.moveItem(srcPath, destFolder + "/" + fileName)
            }
        }
    }

    Component {
        id: contentComp
        ContentView {
            pal: win.pal
            model: win.items
            selectedIds: win.selectedIds
            renamingId: win.renamingId
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                win.showContextMenu(item)
            }
            onEmptyAreaClicked: win.selectedIds = ({})
            onRenameCommitted: function(id, newName) {
                win.renamingId = ""
                var dir = id.substring(0, id.lastIndexOf('/'))
                FsBackend.renameItem(id, dir + "/" + newName)
            }
            onRenameCancelled: win.renamingId = ""
            onItemDroppedOnFolder: function(srcPath, destFolder) {
                var fileName = srcPath.split("/").pop()
                if (fileName) FsBackend.moveItem(srcPath, destFolder + "/" + fileName)
            }
        }
    }

    Component {
        id: tilesComp
        TilesView {
            pal: win.pal
            model: win.items
            selectedIds: win.selectedIds
            renamingId: win.renamingId
            onItemClicked: function(item, ctrl, shift) { win.toggleSelect(item, ctrl, shift) }
            onItemDoubleClicked: function(item) { win.handleOpen(item) }
            onContextMenuRequested: function(item) {
                if (!win.selectedIds[item.id]) { var s = {}; s[item.id] = true; win.selectedIds = s }
                win.showContextMenu(item)
            }
            onRenameCommitted: function(id, newName) {
                win.renamingId = ""
                var dir = id.substring(0, id.lastIndexOf('/'))
                FsBackend.renameItem(id, dir + "/" + newName)
            }
            onRenameCancelled: win.renamingId = ""
            onItemDroppedOnFolder: function(srcPath, destFolder) {
                var fileName = srcPath.split("/").pop()
                if (fileName) FsBackend.moveItem(srcPath, destFolder + "/" + fileName)
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
                win.showContextMenu(item)
            }
            onItemDroppedOnFolder: function(srcPath, destFolder) {
                var fileName = srcPath.split("/").pop()
                if (fileName) FsBackend.moveItem(srcPath, destFolder + "/" + fileName)
            }
        }
    }

    // Lazy-paint flag: heavy UI defers itself until after the first frame so
    // the window appears immediately with just its background colour.
    property bool _heavyReady: false
    Timer {
        interval: 1; running: true; repeat: false
        onTriggered: win._heavyReady = true
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
            pathToCurrent:     win.pathToCurrent
            currentFolderName: win.currentFolderName
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
            onArchivoClicked:     win.handleMenuAction(NativeMenu.showMenuBarMenu("archivo",     win.menuBarParams()))
            onEdicionClicked:     win.handleMenuAction(NativeMenu.showMenuBarMenu("edicion",     win.menuBarParams()))
            onVerClicked:         win.handleMenuAction(NativeMenu.showMenuBarMenu("ver",         win.menuBarParams()))
            onHerramientasClicked:win.handleMenuAction(NativeMenu.showMenuBarMenu("herramientas",win.menuBarParams()))
            onAyudaClicked:       win.handleMenuAction(NativeMenu.showMenuBarMenu("ayuda",       win.menuBarParams()))
        }

        // Command bar
        CommandBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            pal:              win.pal
            selectedCount:    win.selectedCount
            showPreview:      win.showPreview
            viewMode:         win.viewMode
            selectedItemType: win.selectedItemType
            onOrganizeClicked:          win.handleMenuAction(NativeMenu.showOrganizeMenu({ selectedCount: win.selectedCount, showMenuBar: win.showMenuBar, showDetailsPanel: win.showDetailsPanel, showPreview: win.showPreview, showSidebar: win.showSidebar, showContentPreviews: win.showContentPreviews }))
            onDeleteRequested:          win.handleDelete()
            onNewFolderRequested:       win.handleNewFolder()
            onPreviewToggled:           win.showPreview = !win.showPreview
            onViewModeChangeRequested:  function(m) { win.viewMode = m }
            onHelpClicked:              aboutDialog.open()
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
                pal:         win.pal
                currentPath: win.currentId
                favorites:   win.favorites
                onFolderActivated: function(path) {
                    if (path === "network:connect") { connectDriveDialog.open(); return }
                    win.navigate(path)
                }
            }

            // Sidebar splitter
            Rectangle {
                Layout.preferredWidth: win.showSidebar ? 2 : 0
                Layout.maximumWidth:   win.showSidebar ? 2 : 0
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

                // Empty-area right-click — declared BEFORE Loader so it sits behind it.
                // Flickables/ListViews only accept Qt.LeftButton by default, so right-clicks
                // on empty space fall through the view and reach this MouseArea.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: function(mouse) {
                        win.selectedIds = {}
                        win.showContextMenu(null)
                    }
                }

                Loader {
                    id: viewLoader
                    anchors.fill: parent
                    asynchronous: true
                    sourceComponent: {
                        if (win.useGroupedView && win.groupedItems.length === 0) return networkEmptyComp
                        if (win.useGroupedView)        return groupedComp
                        if (win.items.length === 0)    return emptyComp
                        if (win.viewMode === "xlarge" || win.viewMode === "large" ||
                            win.viewMode === "medium" || win.viewMode === "small") return iconsComp
                        if (win.viewMode === "list")    return listComp
                        if (win.viewMode === "details") return detailsComp
                        if (win.viewMode === "tiles")   return tilesComp
                        if (win.viewMode === "content") return contentComp
                        return iconsComp
                    }
                }
            }

            // Preview splitter
            Rectangle {
                Layout.preferredWidth: win.showPreview ? 2 : 0
                Layout.maximumWidth:   win.showPreview ? 2 : 0
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

        // Details panel drag handle + separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ((win.showDetailsPanel && (win.selectedCount > 0 || win.isSpecialPath)) || win.useGroupedView) ? 2 : 0
            Layout.maximumHeight:   ((win.showDetailsPanel && (win.selectedCount > 0 || win.isSpecialPath)) || win.useGroupedView) ? 2 : 0
            color: win.pal.borderSoft
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SplitVCursor
                property int startY: 0
                property int startH: 0
                onPressed:         function(mouse) { startY = mouse.y; startH = detailsPanel.panelHeight }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        detailsPanel.panelHeight = Math.max(40, Math.min(200, startH + (startY - mouse.y)))
                }
            }
        }
        DetailsPanel {
            id: detailsPanel
            Layout.fillWidth: true
            Layout.preferredHeight: ((win.showDetailsPanel && (win.selectedCount > 0 || win.isSpecialPath)) || win.useGroupedView) ? detailsPanel.panelHeight : 0
            Layout.maximumHeight:   ((win.showDetailsPanel && (win.selectedCount > 0 || win.isSpecialPath)) || win.useGroupedView) ? 200 : 0
            clip: true
            pal:                 win.pal
            detailItem:          win.selectedItem
            selectedCount:       win.selectedCount
            currentFolderName:   win.currentFolderName
            currentItemCount:    win.currentItemCount
            totalSelectedSize:   win.totalSelectedSizeStr
            currentFolderIconSrc: win.currentFolderIconSrc
            useGroupedView:      win.useGroupedView
            currentKind:         win.currentNode ? (win.currentNode.kind || "") : ""
            systemInfo:          (win.useGroupedView && win.currentNode && win.currentNode.kind === "computer")
                                     ? FsBackend.getSystemInfo() : null
        }

        // Status bar
        StatusBar {
            Layout.fillWidth: true
            Layout.preferredHeight: (win.showStatusBar && win.selectedCount > 1) ? 24 : 0
            Layout.maximumHeight:   (win.showStatusBar && win.selectedCount > 1) ? 24 : 0
            visible: win.showStatusBar && win.selectedCount > 1
            pal:           win.pal
            itemCount:     win.useGroupedView ? win.groupedItems.length : win.items.length
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
