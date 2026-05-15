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
        text: (i18n.lang, i18n.t("Abrir"))
        enabled: root.targetItem !== null
        visible: !root.isEmpty
        onTriggered: root.openRequested(root.targetItem)
    }
    W7Item {
        text: (i18n.lang, i18n.t("Abrir en nueva ventana"))
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: {}
    }

    W7Menu {
        title: (i18n.lang, i18n.t("Incluir en biblioteca"))
        visible: root.isFolder; enabled: root.isFolder
        W7Item { text: (i18n.lang, i18n.t("Documentos")) }
        W7Item { text: (i18n.lang, i18n.t("Imágenes")) }
        W7Item { text: (i18n.lang, i18n.t("Música")) }
        W7Item { text: (i18n.lang, i18n.t("Vídeos")) }
        W7Sep {}
        W7Item { text: (i18n.lang, i18n.t("Nueva biblioteca…")) }
    }

    W7Menu {
        title: (i18n.lang, i18n.t("Abrir con"))
        visible: root.isFile; enabled: root.isFile
        W7Item { text: (i18n.lang, i18n.t("Aplicación predeterminada")); onTriggered: {} }
        W7Sep {}
        W7Item { text: (i18n.lang, i18n.t("Otra aplicación…")); onTriggered: {} }
    }

    W7Sep { visible: !root.isEmpty }

    W7Menu {
        title: (i18n.lang, i18n.t("Enviar a"))
        visible: !root.isEmpty; enabled: !root.isEmpty
        W7Item { text: (i18n.lang, i18n.t("Escritorio (crear acceso directo)")) }
        W7Item { text: (i18n.lang, i18n.t("Destinatario de correo")) }
        W7Item { text: (i18n.lang, i18n.t("Documentos")) }
    }

    W7Item { text: (i18n.lang, i18n.t("Cortar"));  enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.cutRequested() }
    W7Item { text: (i18n.lang, i18n.t("Copiar"));  enabled: root.hasSelection; visible: !root.isEmpty; onTriggered: root.copyRequested() }
    W7Item { text: (i18n.lang, i18n.t("Pegar"));   visible: !root.isEmpty;                             onTriggered: root.pasteRequested() }

    W7Sep { visible: !root.isEmpty }

    W7Item {
        text: (i18n.lang, i18n.t("Agregar a Favoritos"))
        enabled: root.isFolder; visible: root.isFolder
        onTriggered: root.addToFavoritesRequested()
    }
    W7Menu {
        title: (i18n.lang, i18n.t("Compartir con"))
        visible: root.isFolder; enabled: root.isFolder
        W7Item { text: (i18n.lang, i18n.t("Grupo en el hogar (Ver y modificar)")) }
        W7Item { text: (i18n.lang, i18n.t("Grupo en el hogar (Ver)")) }
        W7Item { text: (i18n.lang, i18n.t("Usuarios específicos…")) }
        W7Sep {}
        W7Item { text: (i18n.lang, i18n.t("Sin conexión disponible")); enabled: false }
    }
    W7Item {
        text: (i18n.lang, i18n.t("Personalizar esta carpeta…"))
        visible: root.isFolder; enabled: root.isFolder
        onTriggered: {}
    }
    W7Item {
        text: (i18n.lang, i18n.t("Crear acceso directo"))
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.shortcutRequested()
    }
    W7Item {
        text: (i18n.lang, i18n.t("Eliminar"))
        enabled: root.hasSelection; visible: !root.isEmpty
        onTriggered: root.deleteRequested()
    }
    W7Item {
        text: (i18n.lang, i18n.t("Cambiar nombre"))
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.renameRequested()
    }

    W7Sep { visible: !root.isEmpty }
    W7Item {
        text: (i18n.lang, i18n.t("Propiedades"))
        enabled: root.targetItem !== null; visible: !root.isEmpty
        onTriggered: root.propertiesRequested()
    }

    // ── Empty area ─────────────────────────────────────────────────────────
    W7Menu {
        title: (i18n.lang, i18n.t("Ver"))
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: (i18n.lang, i18n.t("Iconos muy grandes")); checkable: true; checked: root.viewMode==="xlarge";  onTriggered: root.viewModeChangeRequested("xlarge") }
        W7Item { text: (i18n.lang, i18n.t("Iconos grandes"));     checkable: true; checked: root.viewMode==="large";   onTriggered: root.viewModeChangeRequested("large") }
        W7Item { text: (i18n.lang, i18n.t("Iconos medianos"));    checkable: true; checked: root.viewMode==="medium";  onTriggered: root.viewModeChangeRequested("medium") }
        W7Item { text: (i18n.lang, i18n.t("Iconos pequeños"));    checkable: true; checked: root.viewMode==="small";   onTriggered: root.viewModeChangeRequested("small") }
        W7Item { text: (i18n.lang, i18n.t("Lista"));              checkable: true; checked: root.viewMode==="list";    onTriggered: root.viewModeChangeRequested("list") }
        W7Item { text: (i18n.lang, i18n.t("Detalles"));           checkable: true; checked: root.viewMode==="details"; onTriggered: root.viewModeChangeRequested("details") }
        W7Item { text: (i18n.lang, i18n.t("Mosaicos"));           checkable: true; checked: root.viewMode==="tiles";   onTriggered: root.viewModeChangeRequested("tiles") }
        W7Item { text: (i18n.lang, i18n.t("Contenido"));          checkable: true; checked: root.viewMode==="content"; onTriggered: root.viewModeChangeRequested("content") }
    }

    W7Menu {
        title: (i18n.lang, i18n.t("Ordenar por"))
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: (i18n.lang, i18n.t("Nombre"));                checkable: true; checked: root.sortBy==="name";     onTriggered: root.sortRequested("name") }
        W7Item { text: (i18n.lang, i18n.t("Fecha de modificación")); checkable: true; checked: root.sortBy==="modified"; onTriggered: root.sortRequested("modified") }
        W7Item { text: (i18n.lang, i18n.t("Tipo"));                  checkable: true; checked: root.sortBy==="type";     onTriggered: root.sortRequested("type") }
        W7Item { text: (i18n.lang, i18n.t("Tamaño"));                checkable: true; checked: root.sortBy==="size";     onTriggered: root.sortRequested("size") }
        W7Sep {}
        W7Item { text: (i18n.lang, i18n.t("Ascendente"));  checkable: true; checked: root.sortDir==="asc";  onTriggered: root.sortDirRequested("asc") }
        W7Item { text: (i18n.lang, i18n.t("Descendente")); checkable: true; checked: root.sortDir==="desc"; onTriggered: root.sortDirRequested("desc") }
    }

    W7Menu {
        title: (i18n.lang, i18n.t("Agrupar por"))
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: (i18n.lang, i18n.t("(Ninguno)"));             checkable: true; checked: root.groupBy==="none";     onTriggered: root.groupRequested("none") }
        W7Sep {}
        W7Item { text: (i18n.lang, i18n.t("Nombre"));                checkable: true; checked: root.groupBy==="name";     onTriggered: root.groupRequested("name") }
        W7Item { text: (i18n.lang, i18n.t("Fecha de modificación")); checkable: true; checked: root.groupBy==="modified"; onTriggered: root.groupRequested("modified") }
        W7Item { text: (i18n.lang, i18n.t("Tipo"));                  checkable: true; checked: root.groupBy==="type";     onTriggered: root.groupRequested("type") }
        W7Item { text: (i18n.lang, i18n.t("Tamaño"));                checkable: true; checked: root.groupBy==="size";     onTriggered: root.groupRequested("size") }
    }

    W7Item { text: (i18n.lang, i18n.t("Actualizar")); visible: root.isEmpty; onTriggered: root.refreshRequested() }

    W7Sep { visible: root.isEmpty }
    W7Item { text: (i18n.lang, i18n.t("Pegar"));                visible: root.isEmpty; onTriggered: root.pasteRequested() }
    W7Item { text: (i18n.lang, i18n.t("Pegar acceso directo")); visible: root.isEmpty; onTriggered: {} }
    W7Sep { visible: root.isEmpty }
    W7Menu {
        title: (i18n.lang, i18n.t("Nuevo"))
        visible: root.isEmpty; enabled: root.isEmpty
        W7Item { text: (i18n.lang, i18n.t("Carpeta"));        onTriggered: root.newFolderRequested() }
        W7Item { text: (i18n.lang, i18n.t("Acceso directo")); onTriggered: {} }
    }
    W7Sep { visible: root.isEmpty }
    W7Item { text: (i18n.lang, i18n.t("Propiedades")); visible: root.isEmpty; onTriggered: root.refreshRequested() }
}
