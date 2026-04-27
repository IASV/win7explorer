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

    // ── Win7 popup background (white + gray border + left icon strip) ─────
    background: Rectangle {
        color: "#ffffff"
        border.color: "#acacac"
        border.width: 1
        // Left icon-column strip
        Rectangle {
            x: 1; y: 1
            width: 25; height: parent.height - 2
            color: "#f0f0f0"
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 1; color: "#d4d0c8"
            }
        }
    }

    // ── Inline Win7 components ────────────────────────────────────────────

    // Win7 menu item: gradient blue hover, 22px height, text at 28px
    component W7Item: MenuItem {
        id: ctrl
        implicitHeight: 22
        leftPadding: 28; rightPadding: 16
        topPadding: 0;   bottomPadding: 0
        font.pixelSize: 12

        background: Rectangle {
            implicitWidth: 200; implicitHeight: 22
            color: "transparent"
            Rectangle {
                visible: ctrl.highlighted
                anchors { fill: parent; margins: 1 }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#e4f0fc" }
                    GradientStop { position: 0.5; color: "#d5e9f9" }
                    GradientStop { position: 1.0; color: "#bad3f5" }
                }
                border.color: "#316ac5"
                border.width: 1
            }
        }
    }

    // Win7 submenu: same popup background as root
    component W7Menu: Menu {
        background: Rectangle {
            color: "#ffffff"
            border.color: "#acacac"
            border.width: 1
            Rectangle {
                x: 1; y: 1
                width: 25; height: parent.height - 2
                color: "#f0f0f0"
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: 1; color: "#d4d0c8"
                }
            }
        }
    }

    // Win7 separator: 7px tall, 1px gray line starting after icon column
    component W7Sep: MenuSeparator {
        contentItem: Item {
            implicitWidth: 200; implicitHeight: 7
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: 28
                anchors.right: parent.right; anchors.rightMargin: 2
                height: 1; color: "#d4d0c8"
            }
        }
        background: Item {}
    }

    // ── File / folder selected ────────────────────────────────────────────
    W7Item {
        text: "Abrir"
        enabled: root.targetItem !== null
        visible: !root.isEmpty
        font.bold: !root.isEmpty
        onTriggered: root.openRequested(root.targetItem)
    }
    W7Item {
        text: "Abrir en nueva ventana"
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: {}
    }

    W7Menu {
        title: "Incluir en biblioteca"
        visible: root.isFolder; enabled: root.isFolder
        W7Item { text: "Documentos" }
        W7Item { text: "Imágenes" }
        W7Item { text: "Música" }
        W7Item { text: "Vídeos" }
        W7Sep {}
        W7Item { text: "Nueva biblioteca…" }
    }

    W7Menu {
        title: "Abrir con"
        visible: root.isFile; enabled: root.isFile
        W7Item { text: "Aplicación predeterminada"; onTriggered: {} }
        W7Sep {}
        W7Item { text: "Otra aplicación…"; onTriggered: {} }
    }

    W7Sep { visible: !root.isEmpty }

    W7Menu {
        title: "Enviar a"
        visible: !root.isEmpty; enabled: !root.isEmpty
        W7Item { text: "Escritorio (crear acceso directo)" }
        W7Item { text: "Destinatario de correo" }
        W7Item { text: "Documentos" }
    }

    W7Item { text: "Cortar";  enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.cutRequested() }
    W7Item { text: "Copiar";  enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.copyRequested() }
    W7Item { text: "Pegar";   visible: !root.isEmpty;                             onTriggered: root.pasteRequested() }

    W7Sep { visible: !root.isEmpty }

    W7Item {
        text: "Agregar a Favoritos"
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: root.addToFavoritesRequested()
    }
    W7Menu {
        title: "Compartir con"
        visible: root.isFolder; enabled: root.isFolder
        W7Item { text: "Grupo en el hogar (Ver y modificar)" }
        W7Item { text: "Grupo en el hogar (Ver)" }
        W7Item { text: "Usuarios específicos…" }
        W7Sep {}
        W7Item { text: "Sin conexión disponible"; enabled: false }
    }
    W7Item {
        text: "Personalizar esta carpeta…"
        visible: root.isFolder; enabled: root.isFolder
        onTriggered: {}
    }
    W7Item {
        text: "Crear acceso directo"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.shortcutRequested()
    }
    W7Item {
        text: "Eliminar"
        enabled: root.hasSelection; visible: !root.isEmpty
        onTriggered: root.deleteRequested()
    }
    W7Item {
        text: "Cambiar nombre"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.renameRequested()
    }

    W7Sep { visible: !root.isEmpty }
    W7Item {
        text: "Propiedades"
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.propertiesRequested()
    }

    // ── Empty area ─────────────────────────────────────────────────────────
    W7Menu {
        title: "Ver"
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: "Iconos muy grandes"; checkable: true; checked: root.viewMode==="xlarge";  onTriggered: root.viewModeChangeRequested("xlarge") }
        W7Item { text: "Iconos grandes";     checkable: true; checked: root.viewMode==="large";   onTriggered: root.viewModeChangeRequested("large") }
        W7Item { text: "Iconos medianos";    checkable: true; checked: root.viewMode==="medium";  onTriggered: root.viewModeChangeRequested("medium") }
        W7Item { text: "Iconos pequeños";    checkable: true; checked: root.viewMode==="small";   onTriggered: root.viewModeChangeRequested("small") }
        W7Item { text: "Lista";              checkable: true; checked: root.viewMode==="list";    onTriggered: root.viewModeChangeRequested("list") }
        W7Item { text: "Detalles";           checkable: true; checked: root.viewMode==="details"; onTriggered: root.viewModeChangeRequested("details") }
        W7Item { text: "Mosaicos";           checkable: true; checked: root.viewMode==="tiles";   onTriggered: root.viewModeChangeRequested("tiles") }
        W7Item { text: "Contenido";          checkable: true; checked: root.viewMode==="content"; onTriggered: root.viewModeChangeRequested("content") }
    }

    W7Menu {
        title: "Ordenar por"
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: "Nombre";                checkable: true; checked: root.sortBy==="name";     onTriggered: root.sortRequested("name") }
        W7Item { text: "Fecha de modificación"; checkable: true; checked: root.sortBy==="modified"; onTriggered: root.sortRequested("modified") }
        W7Item { text: "Tipo";                  checkable: true; checked: root.sortBy==="type";     onTriggered: root.sortRequested("type") }
        W7Item { text: "Tamaño";                checkable: true; checked: root.sortBy==="size";     onTriggered: root.sortRequested("size") }
        W7Sep {}
        W7Item { text: "Ascendente";  checkable: true; checked: root.sortDir==="asc";  onTriggered: root.sortDirRequested("asc") }
        W7Item { text: "Descendente"; checkable: true; checked: root.sortDir==="desc"; onTriggered: root.sortDirRequested("desc") }
    }

    W7Menu {
        title: "Agrupar por"
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: "(Ninguno)";             checkable: true; checked: root.groupBy==="none";     onTriggered: root.groupRequested("none") }
        W7Sep {}
        W7Item { text: "Nombre";                checkable: true; checked: root.groupBy==="name";     onTriggered: root.groupRequested("name") }
        W7Item { text: "Fecha de modificación"; checkable: true; checked: root.groupBy==="modified"; onTriggered: root.groupRequested("modified") }
        W7Item { text: "Tipo";                  checkable: true; checked: root.groupBy==="type";     onTriggered: root.groupRequested("type") }
        W7Item { text: "Tamaño";                checkable: true; checked: root.groupBy==="size";     onTriggered: root.groupRequested("size") }
    }

    W7Item { text: "Actualizar"; visible: root.isEmpty; onTriggered: root.refreshRequested() }

    W7Sep { visible: root.isEmpty }
    W7Item { text: "Pegar";                visible: root.isEmpty; onTriggered: root.pasteRequested() }
    W7Item { text: "Pegar acceso directo"; visible: root.isEmpty; onTriggered: {} }
    W7Sep { visible: root.isEmpty }
    W7Menu {
        title: "Nuevo"
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: "Carpeta";        onTriggered: root.newFolderRequested() }
        W7Item { text: "Acceso directo"; onTriggered: {} }
    }
    W7Sep { visible: root.isEmpty }
    W7Item { text: "Propiedades"; visible: root.isEmpty; onTriggered: root.refreshRequested() }
}
