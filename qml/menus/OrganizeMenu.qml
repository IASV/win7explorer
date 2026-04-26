import QtQuick
import QtQuick.Controls

Menu {
    id: root
    property var    pal
    property int    selectedCount:    0
    property bool   showMenuBar:      false
    property bool   showDetailsPanel: false
    property bool   showPreview:      false
    property bool   showSidebar:      true
    property string themeName:        "glass"

    palette.window:          pal.panel
    palette.windowText:      pal.text
    palette.highlight:       pal.accentSoft
    palette.highlightedText: pal.accent

    signal undoRequested
    signal redoRequested
    signal cutRequested
    signal copyRequested
    signal pasteRequested
    signal selectAllRequested
    signal menuBarToggled
    signal detailsPanelToggled
    signal previewToggled
    signal sidebarToggled
    signal deleteRequested
    signal renameRequested
    signal propertiesRequested
    signal closeRequested

    MenuItem { text: "Deshacer"; enabled: false; onTriggered: root.undoRequested() }
    MenuItem { text: "Rehacer"; enabled: false;  onTriggered: root.redoRequested() }
    MenuSeparator {}
    MenuItem { text: "Cortar";  enabled: root.selectedCount > 0; onTriggered: root.cutRequested() }
    MenuItem { text: "Copiar";  enabled: root.selectedCount > 0; onTriggered: root.copyRequested() }
    MenuItem { text: "Pegar";                                    onTriggered: root.pasteRequested() }
    MenuSeparator {}
    MenuItem { text: "Seleccionar todo"; onTriggered: root.selectAllRequested() }
    MenuSeparator {}
    Menu {
        title: "Diseño"
        MenuItem { text: "Barra de menús";        checkable: true; checked: root.showMenuBar;      onTriggered: root.menuBarToggled() }
        MenuItem { text: "Panel de detalles";     checkable: true; checked: root.showDetailsPanel; onTriggered: root.detailsPanelToggled() }
        MenuItem { text: "Panel de vista previa"; checkable: true; checked: root.showPreview;      onTriggered: root.previewToggled() }
        MenuItem { text: "Panel de navegación";   checkable: true; checked: root.showSidebar;      onTriggered: root.sidebarToggled() }
    }
    MenuSeparator {}
    MenuItem { text: "Eliminar";       enabled: root.selectedCount > 0;    onTriggered: root.deleteRequested() }
    MenuItem { text: "Cambiar nombre"; enabled: root.selectedCount === 1;  onTriggered: root.renameRequested() }
    MenuSeparator {}
    MenuItem { text: "Propiedades"; enabled: root.selectedCount > 0;       onTriggered: root.propertiesRequested() }
    MenuSeparator {}
    MenuItem { text: "Cerrar"; onTriggered: root.closeRequested() }
}
