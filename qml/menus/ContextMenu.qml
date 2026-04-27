import QtQuick
import QtQuick.Controls

Menu {
    id: root
    property var pal
    property var targetItem:   null
    property int selectedCount: 0

    property bool hasSelection: selectedCount > 0
    property bool isFolder: targetItem && targetItem.type === "folder"

    palette.window:           pal.panel
    palette.windowText:       pal.text
    palette.base:             pal.content
    palette.text:             pal.text
    palette.highlight:        pal.accentSoft
    palette.highlightedText:  pal.accent

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

    MenuItem { text: "Abrir";                      enabled: root.targetItem !== null;   onTriggered: root.openRequested(root.targetItem) }
    MenuItem { text: "Abrir en una nueva ventana"; enabled: root.isFolder;              onTriggered: {} }
    MenuSeparator {}
    MenuItem { text: "Cortar";    enabled: root.hasSelection; onTriggered: root.cutRequested() }
    MenuItem { text: "Copiar";    enabled: root.hasSelection; onTriggered: root.copyRequested() }
    MenuItem { text: "Pegar";                                 onTriggered: root.pasteRequested() }
    MenuSeparator {}
    MenuItem {
        text: "Agregar a Favoritos"
        enabled: root.isFolder
        visible: root.isFolder
        onTriggered: root.addToFavoritesRequested()
    }
    MenuItem { text: "Crear acceso directo"; enabled: root.targetItem !== null; onTriggered: root.shortcutRequested() }
    MenuItem { text: "Eliminar";             enabled: root.hasSelection;        onTriggered: root.deleteRequested() }
    MenuItem { text: "Cambiar nombre";       enabled: root.targetItem !== null; onTriggered: root.renameRequested() }
    MenuSeparator {}
    MenuItem { text: "Propiedades"; enabled: root.targetItem !== null; onTriggered: root.propertiesRequested() }
    MenuSeparator { visible: root.isFolder || root.targetItem === null }
    MenuItem { text: "Nueva carpeta"; visible: root.isFolder || root.targetItem === null; onTriggered: root.newFolderRequested() }
}
