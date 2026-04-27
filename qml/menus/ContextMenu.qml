import QtQuick
import QtQuick.Controls

Menu {
    id: root
    property var pal
    property var    targetItem:    null
    property int    selectedCount: 0
    property string viewMode:      "large"
    property string sortBy:        "name"

    property bool hasSelection: selectedCount > 0
    property bool isFolder:     targetItem !== null && (targetItem.type === "folder" || targetItem.type === "drive")
    property bool isFile:       targetItem !== null && targetItem.type === "file"
    property bool isEmpty:      targetItem === null

    palette.window:          pal.panel
    palette.windowText:      pal.text
    palette.base:            pal.content
    palette.text:            pal.text
    palette.highlight:       pal.accentSoft
    palette.highlightedText: pal.accent

    signal openRequested(var item)
    signal cutRequested
    signal copyRequested
    signal pasteRequested
    signal shortcutRequested
    signal deleteRequested
    signal renameRequested
    signal propertiesRequested
    signal newFolderRequested
    signal addToFavoritesRequested
    signal viewModeChangeRequested(string mode)
    signal sortRequested(string column)
    signal refreshRequested

    // ── File / folder selected ────────────────────────────────────────────
    MenuItem {
        text: "Abrir"
        enabled: root.targetItem !== null
        visible: !root.isEmpty
        font.bold: !root.isEmpty
        onTriggered: root.openRequested(root.targetItem)
    }
    MenuItem {
        text: "Abrir en nueva ventana"
        enabled: root.isFolder
        visible: root.isFolder
        onTriggered: {}
    }

    // "Abrir con ▶" submenu — only for files
    Menu {
        title: "Abrir con"
        visible: root.isFile
        enabled: root.isFile
        palette: root.palette
        MenuItem { text: "Aplicación predeterminada"; onTriggered: {} }
        MenuSeparator {}
        MenuItem { text: "Otra aplicación…"; onTriggered: {} }
    }

    MenuSeparator { visible: !root.isEmpty }

    MenuItem { text: "Cortar";   enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.cutRequested() }
    MenuItem { text: "Copiar";   enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.copyRequested() }
    MenuItem { text: "Pegar";    visible: !root.isEmpty;                             onTriggered: root.pasteRequested() }

    MenuSeparator { visible: !root.isEmpty }

    MenuItem {
        text: "Agregar a Favoritos"
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: root.addToFavoritesRequested()
    }
    MenuItem {
        text: "Crear acceso directo"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.shortcutRequested()
    }
    MenuItem {
        text: "Eliminar"
        enabled: root.hasSelection; visible: !root.isEmpty
        onTriggered: root.deleteRequested()
    }
    MenuItem {
        text: "Cambiar nombre"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.renameRequested()
    }

    MenuSeparator { visible: !root.isEmpty }
    MenuItem {
        text: "Propiedades"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.propertiesRequested()
    }

    // ── Empty area ─────────────────────────────────────────────────────────
    Menu {
        title: "Ver"
        visible: root.isEmpty
        enabled: root.isEmpty
        palette: root.palette
        MenuItem {
            text: "Iconos grandes"
            checkable: true; checked: root.viewMode === "large"
            onTriggered: root.viewModeChangeRequested("large")
        }
        MenuItem {
            text: "Iconos medianos"
            checkable: true; checked: root.viewMode === "medium"
            onTriggered: root.viewModeChangeRequested("medium")
        }
        MenuItem {
            text: "Lista"
            checkable: true; checked: root.viewMode === "list"
            onTriggered: root.viewModeChangeRequested("list")
        }
        MenuItem {
            text: "Detalles"
            checkable: true; checked: root.viewMode === "details"
            onTriggered: root.viewModeChangeRequested("details")
        }
        MenuItem {
            text: "Contenido"
            checkable: true; checked: root.viewMode === "content"
            onTriggered: root.viewModeChangeRequested("content")
        }
    }

    Menu {
        title: "Ordenar por"
        visible: root.isEmpty
        enabled: root.isEmpty
        palette: root.palette
        MenuItem {
            text: "Nombre"
            checkable: true; checked: root.sortBy === "name"
            onTriggered: root.sortRequested("name")
        }
        MenuItem {
            text: "Fecha de modificación"
            checkable: true; checked: root.sortBy === "modified"
            onTriggered: root.sortRequested("modified")
        }
        MenuItem {
            text: "Tipo"
            checkable: true; checked: root.sortBy === "type"
            onTriggered: root.sortRequested("type")
        }
        MenuItem {
            text: "Tamaño"
            checkable: true; checked: root.sortBy === "size"
            onTriggered: root.sortRequested("size")
        }
    }

    MenuItem {
        text: "Actualizar"
        visible: root.isEmpty
        onTriggered: root.refreshRequested()
    }

    MenuSeparator { visible: root.isEmpty }
    MenuItem {
        text: "Pegar"
        visible: root.isEmpty
        onTriggered: root.pasteRequested()
    }
    MenuSeparator { visible: root.isEmpty }
    MenuItem {
        text: "Nueva carpeta"
        visible: root.isEmpty
        onTriggered: root.newFolderRequested()
    }
}
