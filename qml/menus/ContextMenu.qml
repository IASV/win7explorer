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

    MenuItem { text: "Abrir";                    enabled: root.targetItem !== null;   icon.source: "qrc:/icons/open.png";           onTriggered: root.openRequested(root.targetItem) }
    MenuItem { text: "Abrir en una nueva ventana"; enabled: root.isFolder;            icon.source: "qrc:/icons/open-new-window.png"; onTriggered: {} }
    MenuSeparator {}
    MenuItem { text: "Cortar";    enabled: root.hasSelection; icon.source: "qrc:/icons/cut.png";        onTriggered: root.cutRequested() }
    MenuItem { text: "Copiar";    enabled: root.hasSelection; icon.source: "qrc:/icons/copy.png";       onTriggered: root.copyRequested() }
    MenuItem { text: "Pegar";                               icon.source: "qrc:/icons/paste.png";      onTriggered: root.pasteRequested() }
    MenuSeparator {}
    MenuItem { text: "Crear acceso directo"; enabled: root.targetItem !== null; icon.source: "qrc:/icons/shortcut.png"; onTriggered: root.shortcutRequested() }
    MenuItem { text: "Eliminar";      enabled: root.hasSelection;      icon.source: "qrc:/icons/delete.png";     onTriggered: root.deleteRequested() }
    MenuItem { text: "Cambiar nombre"; enabled: root.targetItem !== null; icon.source: "qrc:/icons/rename.png"; onTriggered: root.renameRequested() }
    MenuSeparator {}
    MenuItem { text: "Propiedades"; enabled: root.targetItem !== null; icon.source: "qrc:/icons/properties.png"; onTriggered: root.propertiesRequested() }
    MenuSeparator { visible: root.isFolder || root.targetItem === null }
    MenuItem { text: "Nueva carpeta"; visible: root.isFolder || root.targetItem === null; icon.source: "qrc:/icons/new-folder.png"; onTriggered: root.newFolderRequested() }
}
