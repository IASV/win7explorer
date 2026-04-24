import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

Rectangle {
    id: contentArea
    color: Win7Theme.contentBg

    property string viewMode: "icons-medium"
    property int iconSize: viewMode === "icons-large" ? Win7Theme.iconSizeLarge
                         : viewMode === "icons-medium" ? Win7Theme.iconSizeMedium
                         : Win7Theme.iconSizeSmall

    // ── Search ──
    property string searchQuery: ""
    readonly property var displayFiles: {
        if (!searchQuery)
            return fileSystemBackend.currentFiles
        let q = searchQuery.toLowerCase()
        return fileSystemBackend.currentFiles.filter(f => f.name.toLowerCase().indexOf(q) >= 0)
    }

    // ── Clipboard state ──
    property string cbPath: ""
    property string cbMode: "copy"
    property bool hasClipboard: cbPath !== ""

    // ── Public API for CommandBar ──
    function openNewFolderDialog() {
        newFolderField.text = "Nueva carpeta"
        newFolderDialog.open()
    }

    function openRenameDialog(path, name) {
        renameOldPath = path
        renameField.text = name
        renameDialog.open()
    }

    function openDeleteDialog(path) {
        deleteTargetPath = path
        deleteDialog.open()
    }

    // ── Paste ──
    function pasteItem() {
        if (!hasClipboard) return
        let filename = cbPath.split("/").pop()
        let destPath = fileSystemBackend.currentPath + "/" + filename
        if (cbMode === "cut") {
            if (fileSystemBackend.moveItem(cbPath, destPath))
                cbPath = ""
        } else {
            fileSystemBackend.copyItem(cbPath, destPath)
        }
    }

    // ── Keyboard shortcuts ──
    Shortcut {
        sequence: "Ctrl+C"
        onActivated: {
            let p = fileSystemBackend.selectedFileInfo.path
            if (p) { cbPath = p; cbMode = "copy" }
        }
    }
    Shortcut {
        sequence: "Ctrl+X"
        onActivated: {
            let p = fileSystemBackend.selectedFileInfo.path
            if (p) { cbPath = p; cbMode = "cut" }
        }
    }
    Shortcut { sequence: "Ctrl+V"; onActivated: pasteItem() }
    Shortcut {
        sequence: "Delete"
        onActivated: {
            let p = fileSystemBackend.selectedFileInfo.path
            if (p) openDeleteDialog(p)
        }
    }
    Shortcut {
        sequence: "F2"
        onActivated: {
            let info = fileSystemBackend.selectedFileInfo
            if (info.path) openRenameDialog(info.path, info.name)
        }
    }
    Shortcut { sequence: "F5"; onActivated: fileSystemBackend.refresh() }

    // ── Item context menu (right-click on file/folder) ──
    Menu {
        id: itemContextMenu
        property string targetPath: ""
        property string targetName: ""
        property bool targetIsDir: false

        MenuItem {
            text: itemContextMenu.targetIsDir ? "Abrir" : "Abrir"
            onTriggered: fileSystemBackend.navigateTo(itemContextMenu.targetPath)
        }
        MenuSeparator {}
        MenuItem {
            text: "Cortar"
            onTriggered: { cbPath = itemContextMenu.targetPath; cbMode = "cut" }
        }
        MenuItem {
            text: "Copiar"
            onTriggered: { cbPath = itemContextMenu.targetPath; cbMode = "copy" }
        }
        MenuItem {
            text: "Pegar"
            enabled: hasClipboard
            onTriggered: pasteItem()
        }
        MenuSeparator {}
        MenuItem {
            text: "Eliminar"
            onTriggered: openDeleteDialog(itemContextMenu.targetPath)
        }
        MenuItem {
            text: "Cambiar nombre"
            onTriggered: openRenameDialog(itemContextMenu.targetPath, itemContextMenu.targetName)
        }
        MenuSeparator {}
        MenuItem {
            text: "Nueva carpeta"
            onTriggered: openNewFolderDialog()
        }
    }

    // ── Background context menu (right-click on empty area) ──
    Menu {
        id: bgContextMenu
        MenuItem {
            text: "Pegar"
            enabled: hasClipboard
            onTriggered: pasteItem()
        }
        MenuSeparator {}
        MenuItem { text: "Nueva carpeta"; onTriggered: openNewFolderDialog() }
        MenuItem { text: "Actualizar"; onTriggered: fileSystemBackend.refresh() }
    }

    // ── Delete confirmation dialog ──
    property string deleteTargetPath: ""
    Dialog {
        id: deleteDialog
        title: "Eliminar"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel

        Label {
            text: "¿Eliminar permanentemente \"" + deleteTargetPath.split("/").pop() + "\"?"
            wrapMode: Text.WordWrap
            width: 320
        }

        onAccepted: fileSystemBackend.removeItem(deleteTargetPath)
    }

    // ── Rename dialog ──
    property string renameOldPath: ""
    Dialog {
        id: renameDialog
        title: "Cambiar nombre"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel

        TextField {
            id: renameField
            width: 320
            selectByMouse: true
            onAccepted: renameDialog.accept()
        }

        onOpened: { renameField.forceActiveFocus(); renameField.selectAll() }
        onAccepted: {
            let trimmed = renameField.text.trim()
            if (trimmed === "") return
            let dir = renameOldPath.substring(0, renameOldPath.lastIndexOf("/"))
            fileSystemBackend.renameItem(renameOldPath, dir + "/" + trimmed)
        }
    }

    // ── New folder dialog ──
    Dialog {
        id: newFolderDialog
        title: "Nueva carpeta"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel

        TextField {
            id: newFolderField
            width: 320
            selectByMouse: true
            onAccepted: newFolderDialog.accept()
        }

        onOpened: { newFolderField.forceActiveFocus(); newFolderField.selectAll() }
        onAccepted: {
            let name = newFolderField.text.trim()
            if (name !== "") fileSystemBackend.createFolder("", name)
        }
    }

    // ── Library Header ──
    Rectangle {
        id: libraryHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 45
        color: Win7Theme.contentBg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            ColumnLayout {
                spacing: 0

                Text {
                    text: {
                        if (contentArea.searchQuery)
                            return "Resultados de búsqueda"
                        let segments = fileSystemBackend.pathSegments
                        if (segments.length > 0)
                            return segments[segments.length - 1].name
                        return "/"
                    }
                    font.family: Win7Theme.fontFamily
                    font.pixelSize: Win7Theme.fontSizeTitle
                    color: Win7Theme.libraryHeaderText
                }

                Text {
                    text: contentArea.searchQuery
                          ? "\"" + contentArea.searchQuery + "\" — " + fileSystemBackend.currentPath
                          : fileSystemBackend.currentPath
                    font.family: Win7Theme.fontFamily
                    font.pixelSize: Win7Theme.fontSizeSmall + 2
                    color: Win7Theme.librarySubText
                    visible: text !== ""
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 4

                Text {
                    text: "Organizar por:"
                    font.family: Win7Theme.fontFamily
                    font.pixelSize: Win7Theme.fontSizeNormal + 1
                    color: Win7Theme.librarySubText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: orgLabel.implicitWidth + 16
                    height: 20
                    radius: 2
                    color: orgMa.containsMouse ? Win7Theme.cmdBarBtnHover : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: orgLabel
                        anchors.centerIn: parent
                        text: "Carpeta ▾"
                        font.family: Win7Theme.fontFamily
                        font.pixelSize: Win7Theme.fontSizeNormal + 1
                        color: Win7Theme.navPanelHeaderText
                    }

                    MouseArea { id: orgMa; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Win7Theme.contentHeaderBorder
        }
    }

    // ── Column Headers (details view) ──
    Rectangle {
        id: columnHeaders
        anchors.top: libraryHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Win7Theme.columnHeaderHeight
        color: Win7Theme.columnHeaderBg
        visible: contentArea.viewMode === "details"

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Win7Theme.columnHeaderBorder
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 4

            ColumnHeader { text: "Nombre"; width: 250 }
            ColumnHeader { text: "Fecha de modificación"; width: 150 }
            ColumnHeader { text: "Tipo"; width: 140 }
            ColumnHeader { text: "Tamaño"; width: 100 }
        }
    }

    // ── File Listing ──
    ScrollView {
        id: scrollView
        anchors.top: contentArea.viewMode === "details" ? columnHeaders.bottom
                                                        : libraryHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        // Icon Grid View
        GridView {
            id: iconGridView
            visible: contentArea.viewMode !== "details" && contentArea.viewMode !== "list"
            anchors.fill: parent
            anchors.margins: 8
            cellWidth: contentArea.viewMode === "icons-large" ? 130 : 90
            cellHeight: contentArea.viewMode === "icons-large" ? 130 : 90
            model: contentArea.displayFiles

            delegate: Item {
                width: iconGridView.cellWidth
                height: iconGridView.cellHeight

                Rectangle {
                    id: iconDelegate
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height - 4
                    radius: 3
                    color: {
                        let selected = fileSystemBackend.selectedFileInfo.path === modelData.path
                        if (selected) return Win7Theme.selectionBg
                        if (iconMa.containsMouse) return Win7Theme.selectionHoverBg
                        return "transparent"
                    }
                    border.color: {
                        let selected = fileSystemBackend.selectedFileInfo.path === modelData.path
                        if (selected) return Win7Theme.selectionBorder
                        if (iconMa.containsMouse) return Win7Theme.selectionHoverBorder
                        return "transparent"
                    }
                    border.width: 1

                    // Cut item visual feedback
                    opacity: (cbMode === "cut" && cbPath === modelData.path) ? 0.5 : 1.0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isDir ? "📁" : fileIconEmoji(modelData.name)
                                font.pixelSize: contentArea.iconSize * 0.7
                                opacity: modelData.isHidden ? 0.5 : 1.0
                            }
                        }

                        Text {
                            text: modelData.name
                            font.family: Win7Theme.fontFamily
                            font.pixelSize: Win7Theme.fontSizeNormal + 1
                            color: Win7Theme.itemText
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            elide: Text.ElideMiddle
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            opacity: modelData.isHidden ? 0.5 : 1.0
                        }
                    }

                    MouseArea {
                        id: iconMa
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: (mouse) => {
                            fileSystemBackend.selectFile(modelData.path)
                            if (mouse.button === Qt.RightButton) {
                                itemContextMenu.targetPath = modelData.path
                                itemContextMenu.targetName = modelData.name
                                itemContextMenu.targetIsDir = modelData.isDir
                                itemContextMenu.popup()
                            }
                        }
                        onDoubleClicked: {
                            if (modelData.isDir)
                                fileSystemBackend.navigateTo(modelData.path)
                        }
                    }
                }
            }
        }

        // Details View
        ListView {
            id: detailsListView
            visible: contentArea.viewMode === "details"
            anchors.fill: parent
            model: contentArea.displayFiles
            clip: true

            delegate: Rectangle {
                width: detailsListView.width
                height: 22
                color: {
                    let selected = fileSystemBackend.selectedFileInfo.path === modelData.path
                    if (selected) return Win7Theme.selectionBg
                    if (detailMa.containsMouse) return Win7Theme.selectionHoverBg
                    return index % 2 === 0 ? "transparent" : "#F8F8F8"
                }
                border.color: fileSystemBackend.selectedFileInfo.path === modelData.path
                              ? Win7Theme.selectionBorder : "transparent"
                border.width: fileSystemBackend.selectedFileInfo.path === modelData.path ? 1 : 0

                opacity: (cbMode === "cut" && cbPath === modelData.path) ? 0.5 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    spacing: 0

                    Row {
                        Layout.preferredWidth: 250
                        spacing: 4
                        clip: true

                        Text {
                            text: modelData.isDir ? "📁" : "📄"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.name
                            font.family: Win7Theme.fontFamily
                            font.pixelSize: Win7Theme.fontSizeNormal + 1
                            color: Win7Theme.itemText
                            elide: Text.ElideRight
                            width: 220
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: modelData.isHidden ? 0.5 : 1.0
                        }
                    }

                    Text {
                        Layout.preferredWidth: 150
                        text: modelData.modified
                        font.family: Win7Theme.fontFamily
                        font.pixelSize: Win7Theme.fontSizeNormal + 1
                        color: Win7Theme.itemTextSecondary
                        clip: true
                    }

                    Text {
                        Layout.preferredWidth: 140
                        text: modelData.type
                        font.family: Win7Theme.fontFamily
                        font.pixelSize: Win7Theme.fontSizeNormal + 1
                        color: Win7Theme.itemTextSecondary
                        elide: Text.ElideRight
                        clip: true
                    }

                    Text {
                        Layout.preferredWidth: 100
                        text: modelData.sizeFormatted
                        font.family: Win7Theme.fontFamily
                        font.pixelSize: Win7Theme.fontSizeNormal + 1
                        color: Win7Theme.itemTextSecondary
                        horizontalAlignment: Text.AlignRight
                    }

                    Item { Layout.fillWidth: true }
                }

                MouseArea {
                    id: detailMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        fileSystemBackend.selectFile(modelData.path)
                        if (mouse.button === Qt.RightButton) {
                            itemContextMenu.targetPath = modelData.path
                            itemContextMenu.targetName = modelData.name
                            itemContextMenu.targetIsDir = modelData.isDir
                            itemContextMenu.popup()
                        }
                    }
                    onDoubleClicked: {
                        if (modelData.isDir)
                            fileSystemBackend.navigateTo(modelData.path)
                    }
                }
            }
        }
    }

    // Empty folder / no results message
    Text {
        anchors.centerIn: parent
        text: contentArea.searchQuery
              ? "No se encontraron resultados para \"" + contentArea.searchQuery + "\"."
              : "Esta carpeta está vacía."
        font.family: Win7Theme.fontFamily
        font.pixelSize: Win7Theme.fontSizeNormal + 2
        color: Win7Theme.itemTextSecondary
        visible: contentArea.displayFiles.length === 0
    }

    // Click/right-click on empty area
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                fileSystemBackend.clearSelection()
            else
                bgContextMenu.popup()
        }
    }

    // ── Column Header component ──
    component ColumnHeader: Rectangle {
        property alias text: headerLabel.text

        height: parent.height
        color: colMa.containsPress ? Win7Theme.columnHeaderPressed
             : colMa.containsMouse ? Win7Theme.columnHeaderHover
             : Win7Theme.columnHeaderBg

        Rectangle {
            anchors.right: parent.right
            height: parent.height
            width: 1
            color: Win7Theme.columnHeaderBorder
        }

        Text {
            id: headerLabel
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 6
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeNormal + 1
            color: Win7Theme.columnHeaderText
        }

        MouseArea { id: colMa; anchors.fill: parent; hoverEnabled: true }
    }

    function fileIconEmoji(filename) {
        let ext = filename.split('.').pop().toLowerCase()
        switch (ext) {
            case "jpg": case "jpeg": case "png": case "gif":
            case "bmp": case "svg": case "webp": return "🖼"
            case "mp3": case "wav": case "flac": case "ogg":
            case "aac": case "wma": return "🎵"
            case "mp4": case "avi": case "mkv": case "mov":
            case "wmv": case "flv": case "webm": return "🎬"
            case "pdf": return "📕"
            case "doc": case "docx": case "odt": return "📝"
            case "xls": case "xlsx": case "ods": return "📊"
            case "ppt": case "pptx": case "odp": return "📊"
            case "zip": case "tar": case "gz": case "7z":
            case "rar": case "bz2": case "xz": return "📦"
            case "exe": case "msi": case "appimage":
            case "deb": case "rpm": return "⚙"
            case "py": case "js": case "cpp": case "c":
            case "h": case "java": case "rs": case "go":
            case "sh": case "bash": return "📜"
            case "html": case "css": case "xml": case "json": return "🌐"
            default: return "📄"
        }
    }
}
