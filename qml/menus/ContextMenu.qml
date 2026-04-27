import QtQuick
import QtQuick.Controls

Menu {
    id: root
    property var pal
    property var    targetItem:    null
    property int    selectedCount: 0
    property string viewMode:      "large"
    property string sortBy:        "name"
    property string sortDir:       "asc"
    property string groupBy:       "none"

    property bool hasSelection: selectedCount > 0
    property bool isFolder:     targetItem !== null && (targetItem.type === "folder" || targetItem.type === "drive")
    property bool isFile:       targetItem !== null && targetItem.type === "file"
    property bool isEmpty:      targetItem === null


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
    signal sortDirRequested(string dir)
    signal groupRequested(string column)
    signal refreshRequested

    // ── File / folder selected ────────────────────────────────────────────
    MenuItem {
        text: "Abrir"
        icon.name: "document-open"
        enabled: root.targetItem !== null
        visible: !root.isEmpty
        font.bold: !root.isEmpty
        onTriggered: root.openRequested(root.targetItem)
    }
    MenuItem {
        text: "Abrir en nueva ventana"
        icon.name: "window-new"
        enabled: root.isFolder
        visible: root.isFolder
        onTriggered: {}
    }

    Menu {
        title: "Incluir en biblioteca"
        visible: root.isFolder; enabled: root.isFolder

        MenuItem { text: "Documentos";      icon.name: "folder-documents" }
        MenuItem { text: "Imágenes";        icon.name: "folder-pictures" }
        MenuItem { text: "Música";          icon.name: "folder-music" }
        MenuItem { text: "Vídeos";          icon.name: "folder-videos" }
        MenuSeparator {}
        MenuItem { text: "Nueva biblioteca…"; icon.name: "bookmark-new" }
    }

    // "Abrir con ▶" submenu — only for files
    Menu {
        title: "Abrir con"
        visible: root.isFile
        enabled: root.isFile

        MenuItem { text: "Aplicación predeterminada"; icon.name: "system-run";    onTriggered: {} }
        MenuSeparator {}
        MenuItem { text: "Otra aplicación…";          icon.name: "system-search"; onTriggered: {} }
    }

    MenuSeparator { visible: !root.isEmpty }

    Menu {
        title: "Enviar a"
        visible: !root.isEmpty; enabled: !root.isEmpty

        MenuItem { text: "Escritorio (crear acceso directo)"; icon.name: "user-desktop" }
        MenuItem { text: "Destinatario de correo";            icon.name: "mail-send" }
        MenuItem { text: "Documentos";                        icon.name: "folder-documents" }
    }

    MenuItem { text: "Cortar";   icon.name: "edit-cut";   enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.cutRequested() }
    MenuItem { text: "Copiar";   icon.name: "edit-copy";  enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.copyRequested() }
    MenuItem { text: "Pegar";    icon.name: "edit-paste"; visible: !root.isEmpty;                             onTriggered: root.pasteRequested() }

    MenuSeparator { visible: !root.isEmpty }

    MenuItem {
        text: "Agregar a Favoritos"
        icon.name: "bookmark-new"
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: root.addToFavoritesRequested()
    }
    Menu {
        title: "Compartir con"
        visible: root.isFolder; enabled: root.isFolder

        MenuItem { text: "Grupo en el hogar (Ver y modificar)"; icon.name: "network-workgroup" }
        MenuItem { text: "Grupo en el hogar (Ver)";             icon.name: "network-workgroup" }
        MenuItem { text: "Usuarios específicos…";               icon.name: "system-users" }
        MenuSeparator {}
        MenuItem { text: "Sin conexión disponible"; enabled: false }
    }
    MenuItem {
        text: "Personalizar esta carpeta…"
        icon.name: "document-properties"
        visible: root.isFolder; enabled: root.isFolder
        onTriggered: {}
    }
    MenuItem {
        text: "Crear acceso directo"
        icon.name: "insert-link"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.shortcutRequested()
    }
    MenuItem {
        text: "Eliminar"
        icon.name: "edit-delete"
        enabled: root.hasSelection; visible: !root.isEmpty
        onTriggered: root.deleteRequested()
    }
    MenuItem {
        text: "Cambiar nombre"
        icon.name: "document-edit"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.renameRequested()
    }

    MenuSeparator { visible: !root.isEmpty }
    MenuItem {
        text: "Propiedades"
        icon.name: "document-properties"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.propertiesRequested()
    }

    // ── Empty area ─────────────────────────────────────────────────────────
    Menu {
        title: "Ver"
        visible: root.isEmpty
        enabled: root.isEmpty

        MenuItem { text: "Iconos muy grandes"; icon.name: "view-list-icons";   checkable: true; checked: root.viewMode === "xlarge";  onTriggered: root.viewModeChangeRequested("xlarge") }
        MenuItem { text: "Iconos grandes";     icon.name: "view-list-icons";   checkable: true; checked: root.viewMode === "large";   onTriggered: root.viewModeChangeRequested("large") }
        MenuItem { text: "Iconos medianos";    icon.name: "view-list-icons";   checkable: true; checked: root.viewMode === "medium";  onTriggered: root.viewModeChangeRequested("medium") }
        MenuItem { text: "Iconos pequeños";    icon.name: "view-list-icons";   checkable: true; checked: root.viewMode === "small";   onTriggered: root.viewModeChangeRequested("small") }
        MenuItem { text: "Lista";              icon.name: "view-list-text";    checkable: true; checked: root.viewMode === "list";    onTriggered: root.viewModeChangeRequested("list") }
        MenuItem { text: "Detalles";           icon.name: "view-list-details"; checkable: true; checked: root.viewMode === "details"; onTriggered: root.viewModeChangeRequested("details") }
        MenuItem { text: "Mosaicos";           icon.name: "view-list-icons";   checkable: true; checked: root.viewMode === "tiles";   onTriggered: root.viewModeChangeRequested("tiles") }
        MenuItem { text: "Contenido";          icon.name: "view-list-text";    checkable: true; checked: root.viewMode === "content"; onTriggered: root.viewModeChangeRequested("content") }
    }

    Menu {
        title: "Ordenar por"
        visible: root.isEmpty
        enabled: root.isEmpty

        MenuItem { text: "Nombre";               icon.name: "view-sort-ascending";  checkable: true; checked: root.sortBy === "name";     onTriggered: root.sortRequested("name") }
        MenuItem { text: "Fecha de modificación"; icon.name: "office-calendar";      checkable: true; checked: root.sortBy === "modified"; onTriggered: root.sortRequested("modified") }
        MenuItem { text: "Tipo";                 icon.name: "preferences-other";    checkable: true; checked: root.sortBy === "type";     onTriggered: root.sortRequested("type") }
        MenuItem { text: "Tamaño";               icon.name: "drive-harddisk";       checkable: true; checked: root.sortBy === "size";     onTriggered: root.sortRequested("size") }
        MenuSeparator {}
        MenuItem { text: "Ascendente";  icon.name: "view-sort-ascending";  checkable: true; checked: root.sortDir === "asc";  onTriggered: root.sortDirRequested("asc") }
        MenuItem { text: "Descendente"; icon.name: "view-sort-descending"; checkable: true; checked: root.sortDir === "desc"; onTriggered: root.sortDirRequested("desc") }
    }

    Menu {
        title: "Agrupar por"
        visible: root.isEmpty
        enabled: root.isEmpty

        MenuItem { text: "(Ninguno)";            checkable: true; checked: root.groupBy === "none";     onTriggered: root.groupRequested("none") }
        MenuSeparator {}
        MenuItem { text: "Nombre";               icon.name: "view-sort-ascending";  checkable: true; checked: root.groupBy === "name";     onTriggered: root.groupRequested("name") }
        MenuItem { text: "Fecha de modificación"; icon.name: "office-calendar";      checkable: true; checked: root.groupBy === "modified"; onTriggered: root.groupRequested("modified") }
        MenuItem { text: "Tipo";                 icon.name: "preferences-other";    checkable: true; checked: root.groupBy === "type";     onTriggered: root.groupRequested("type") }
        MenuItem { text: "Tamaño";               icon.name: "drive-harddisk";       checkable: true; checked: root.groupBy === "size";     onTriggered: root.groupRequested("size") }
    }

    MenuItem {
        text: "Actualizar"
        icon.name: "view-refresh"
        visible: root.isEmpty
        onTriggered: root.refreshRequested()
    }

    MenuSeparator { visible: root.isEmpty }
    MenuItem { text: "Pegar";                icon.name: "edit-paste";   visible: root.isEmpty; onTriggered: root.pasteRequested() }
    MenuItem { text: "Pegar acceso directo"; icon.name: "insert-link";  visible: root.isEmpty; onTriggered: {} }
    MenuSeparator { visible: root.isEmpty }
    Menu {
        title: "Nuevo"
        visible: root.isEmpty; enabled: root.isEmpty

        MenuItem { text: "Carpeta";        icon.name: "folder-new";   onTriggered: root.newFolderRequested() }
        MenuItem { text: "Acceso directo"; icon.name: "insert-link";  onTriggered: {} }
    }
    MenuSeparator { visible: root.isEmpty }
    MenuItem { text: "Propiedades"; icon.name: "document-properties"; visible: root.isEmpty; onTriggered: root.refreshRequested() }
}
