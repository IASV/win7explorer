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

    Menu {
        title: "Incluir en biblioteca"
        visible: root.isFolder; enabled: root.isFolder

        MenuItem { text: "Documentos" }
        MenuItem { text: "Imágenes" }
        MenuItem { text: "Música" }
        MenuItem { text: "Vídeos" }
        MenuSeparator {}
        MenuItem { text: "Nueva biblioteca…" }
    }

    // "Abrir con ▶" submenu — only for files
    Menu {
        title: "Abrir con"
        visible: root.isFile
        enabled: root.isFile

        MenuItem { text: "Aplicación predeterminada"; onTriggered: {} }
        MenuSeparator {}
        MenuItem { text: "Otra aplicación…"; onTriggered: {} }
    }

    MenuSeparator { visible: !root.isEmpty }

    Menu {
        title: "Enviar a"
        visible: !root.isEmpty; enabled: !root.isEmpty

        MenuItem { text: "Escritorio (crear acceso directo)" }
        MenuItem { text: "Destinatario de correo" }
        MenuItem { text: "Documentos" }
    }

    MenuItem { text: "Cortar";   enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.cutRequested() }
    MenuItem { text: "Copiar";   enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.copyRequested() }
    MenuItem { text: "Pegar";    visible: !root.isEmpty;                             onTriggered: root.pasteRequested() }

    MenuSeparator { visible: !root.isEmpty }

    MenuItem {
        text: "Agregar a Favoritos"
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: root.addToFavoritesRequested()
    }
    Menu {
        title: "Compartir con"
        visible: root.isFolder; enabled: root.isFolder

        MenuItem { text: "Grupo en el hogar (Ver y modificar)" }
        MenuItem { text: "Grupo en el hogar (Ver)" }
        MenuItem { text: "Usuarios específicos…" }
        MenuSeparator {}
        MenuItem { text: "Sin conexión disponible"; enabled: false }
    }
    MenuItem {
        text: "Personalizar esta carpeta…"
        visible: root.isFolder; enabled: root.isFolder
        onTriggered: {}
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

        MenuItem { text: "Iconos muy grandes"; checkable: true; checked: root.viewMode === "xlarge";  onTriggered: root.viewModeChangeRequested("xlarge") }
        MenuItem { text: "Iconos grandes";     checkable: true; checked: root.viewMode === "large";   onTriggered: root.viewModeChangeRequested("large") }
        MenuItem { text: "Iconos medianos";    checkable: true; checked: root.viewMode === "medium";  onTriggered: root.viewModeChangeRequested("medium") }
        MenuItem { text: "Iconos pequeños";    checkable: true; checked: root.viewMode === "small";   onTriggered: root.viewModeChangeRequested("small") }
        MenuItem { text: "Lista";              checkable: true; checked: root.viewMode === "list";    onTriggered: root.viewModeChangeRequested("list") }
        MenuItem { text: "Detalles";           checkable: true; checked: root.viewMode === "details"; onTriggered: root.viewModeChangeRequested("details") }
        MenuItem { text: "Mosaicos";           checkable: true; checked: root.viewMode === "tiles";   onTriggered: root.viewModeChangeRequested("tiles") }
        MenuItem { text: "Contenido";          checkable: true; checked: root.viewMode === "content"; onTriggered: root.viewModeChangeRequested("content") }
    }

    Menu {
        title: "Ordenar por"
        visible: root.isEmpty
        enabled: root.isEmpty

        MenuItem { text: "Nombre";               checkable: true; checked: root.sortBy === "name";     onTriggered: root.sortRequested("name") }
        MenuItem { text: "Fecha de modificación"; checkable: true; checked: root.sortBy === "modified"; onTriggered: root.sortRequested("modified") }
        MenuItem { text: "Tipo";                 checkable: true; checked: root.sortBy === "type";     onTriggered: root.sortRequested("type") }
        MenuItem { text: "Tamaño";               checkable: true; checked: root.sortBy === "size";     onTriggered: root.sortRequested("size") }
        MenuSeparator {}
        MenuItem { text: "Ascendente";  checkable: true; checked: root.sortDir === "asc";  onTriggered: root.sortDirRequested("asc") }
        MenuItem { text: "Descendente"; checkable: true; checked: root.sortDir === "desc"; onTriggered: root.sortDirRequested("desc") }
    }

    Menu {
        title: "Agrupar por"
        visible: root.isEmpty
        enabled: root.isEmpty

        MenuItem { text: "(Ninguno)";            checkable: true; checked: root.groupBy === "none";     onTriggered: root.groupRequested("none") }
        MenuSeparator {}
        MenuItem { text: "Nombre";               checkable: true; checked: root.groupBy === "name";     onTriggered: root.groupRequested("name") }
        MenuItem { text: "Fecha de modificación"; checkable: true; checked: root.groupBy === "modified"; onTriggered: root.groupRequested("modified") }
        MenuItem { text: "Tipo";                 checkable: true; checked: root.groupBy === "type";     onTriggered: root.groupRequested("type") }
        MenuItem { text: "Tamaño";               checkable: true; checked: root.groupBy === "size";     onTriggered: root.groupRequested("size") }
    }

    MenuItem {
        text: "Actualizar"
        visible: root.isEmpty
        onTriggered: root.refreshRequested()
    }

    MenuSeparator { visible: root.isEmpty }
    MenuItem { text: "Pegar";                  visible: root.isEmpty; onTriggered: root.pasteRequested() }
    MenuItem { text: "Pegar acceso directo";   visible: root.isEmpty; onTriggered: {} }
    MenuSeparator { visible: root.isEmpty }
    Menu {
        title: "Nuevo"
        visible: root.isEmpty; enabled: root.isEmpty

        MenuItem { text: "Carpeta";         onTriggered: root.newFolderRequested() }
        MenuItem { text: "Acceso directo";  onTriggered: {} }
    }
    MenuSeparator { visible: root.isEmpty }
    MenuItem { text: "Propiedades";            visible: root.isEmpty; onTriggered: root.refreshRequested() }
}
