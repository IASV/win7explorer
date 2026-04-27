import QtQuick
import QtQuick.Controls

// Container that holds and exposes the 5 Win7 menu-bar menus.
// Usage: MenuBarMenus { id: mb; pal: win.pal; ... }
//        then: mb.archivoMenu.popup() / mb.edicionMenu.popup() / etc.
Item {
    id: root
    property var    pal
    property int    selectedCount:    0
    property string viewMode:         "large"
    property bool   showMenuBar:      false
    property bool   showDetailsPanel: false
    property bool   showPreview:      false
    property bool   showSidebar:      true
    property bool   showStatusBar:    true
    property string themeName:        "glass"

    signal newFolderRequested
    signal deleteRequested
    signal renameRequested
    signal propertiesRequested
    signal closeRequested
    signal cutRequested
    signal copyRequested
    signal pasteRequested
    signal selectAllRequested
    signal invertSelectionRequested
    signal viewModeChangeRequested(string mode)
    signal sortRequested(string col)
    signal menuBarToggled
    signal detailsPanelToggled
    signal previewToggled
    signal sidebarToggled
    signal refreshRequested
    signal statusBarToggled
    signal copyToFolderRequested
    signal moveToFolderRequested
    signal themeChangeRequested(string name)
    signal terminalRequested
    signal helpRequested
    signal aboutRequested

    // Expose menus so parent can call .popup()
    property alias archivoMenu:      _archivoMenu
    property alias edicionMenu:      _edicionMenu
    property alias verMenu:          _verMenu
    property alias herramientasMenu: _herramientasMenu
    property alias ayudaMenu:        _ayudaMenu

    Menu {
        id: _archivoMenu
        palette.window: root.pal.panel; palette.windowText: root.pal.text
        palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
        MenuItem { text: "Nueva carpeta";  onTriggered: root.newFolderRequested() }
        MenuSeparator {}
        MenuItem { text: "Eliminar";       enabled: root.selectedCount > 0;   onTriggered: root.deleteRequested() }
        MenuItem { text: "Cambiar nombre"; enabled: root.selectedCount === 1; onTriggered: root.renameRequested() }
        MenuItem { text: "Propiedades";    enabled: root.selectedCount > 0;   onTriggered: root.propertiesRequested() }
        MenuSeparator {}
        MenuItem { text: "Cerrar"; onTriggered: root.closeRequested() }
    }

    Menu {
        id: _edicionMenu
        palette.window: root.pal.panel; palette.windowText: root.pal.text
        palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
        MenuItem { text: "Deshacer"; enabled: false }
        MenuItem { text: "Rehacer"; enabled: false }
        MenuSeparator {}
        MenuItem { text: "Cortar"; enabled: root.selectedCount > 0; onTriggered: root.cutRequested() }
        MenuItem { text: "Copiar"; enabled: root.selectedCount > 0; onTriggered: root.copyRequested() }
        MenuItem { text: "Pegar"; onTriggered: root.pasteRequested() }
        MenuSeparator {}
        MenuItem { text: "Copiar a la carpeta…"; enabled: root.selectedCount > 0; onTriggered: root.copyToFolderRequested() }
        MenuItem { text: "Mover a la carpeta…";  enabled: root.selectedCount > 0; onTriggered: root.moveToFolderRequested() }
        MenuSeparator {}
        MenuItem { text: "Seleccionar todo";    onTriggered: root.selectAllRequested() }
        MenuItem { text: "Invertir selección";  onTriggered: root.invertSelectionRequested() }
    }

    Menu {
        id: _verMenu
        palette.window: root.pal.panel; palette.windowText: root.pal.text
        palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
        Menu {
            title: "Vista"
            MenuItem { text: "Iconos grandes";  checkable: true; checked: root.viewMode==="large";   onTriggered: root.viewModeChangeRequested("large") }
            MenuItem { text: "Iconos medianos"; checkable: true; checked: root.viewMode==="medium";  onTriggered: root.viewModeChangeRequested("medium") }
            MenuItem { text: "Lista";           checkable: true; checked: root.viewMode==="list";    onTriggered: root.viewModeChangeRequested("list") }
            MenuItem { text: "Detalles";        checkable: true; checked: root.viewMode==="details"; onTriggered: root.viewModeChangeRequested("details") }
            MenuItem { text: "Contenido";       checkable: true; checked: root.viewMode==="content"; onTriggered: root.viewModeChangeRequested("content") }
        }
        Menu {
            title: "Ordenar por"
            MenuItem { text: "Nombre";                onTriggered: root.sortRequested("name") }
            MenuItem { text: "Fecha de modificación"; onTriggered: root.sortRequested("modified") }
            MenuItem { text: "Tipo";                  onTriggered: root.sortRequested("type") }
            MenuItem { text: "Tamaño";                onTriggered: root.sortRequested("size") }
        }
        MenuSeparator {}
        Menu {
            title: "Organizar"
            palette.window: root.pal.panel; palette.windowText: root.pal.text
            palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
            Menu {
                title: "Diseño"
                palette.window: root.pal.panel; palette.windowText: root.pal.text
                palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
                MenuItem { text: "Barra de menús";        checkable: true; checked: root.showMenuBar;      onTriggered: root.menuBarToggled() }
                MenuItem { text: "Panel de detalles";     checkable: true; checked: root.showDetailsPanel; onTriggered: root.detailsPanelToggled() }
                MenuItem { text: "Panel de vista previa"; checkable: true; checked: root.showPreview;      onTriggered: root.previewToggled() }
                MenuItem { text: "Panel de navegación";   checkable: true; checked: root.showSidebar;      onTriggered: root.sidebarToggled() }
                MenuSeparator {}
                MenuItem { text: "Barra de estado";       checkable: true; checked: root.showStatusBar;    onTriggered: root.statusBarToggled() }
            }
        }
        MenuSeparator {}
        MenuItem { text: "Actualizar"; onTriggered: root.refreshRequested() }
    }

    Menu {
        id: _herramientasMenu
        palette.window: root.pal.panel; palette.windowText: root.pal.text
        palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
        MenuItem { text: "Abrir símbolo del sistema"; onTriggered: root.terminalRequested() }
        MenuSeparator {}
        Menu {
            title: "Tema"
            MenuItem { text: "Glass (predeterminado)"; checkable: true; checked: root.themeName==="glass"; onTriggered: root.themeChangeRequested("glass") }
            MenuItem { text: "Plano";                  checkable: true; checked: root.themeName==="flat";  onTriggered: root.themeChangeRequested("flat") }
            MenuItem { text: "Oscuro";                 checkable: true; checked: root.themeName==="dark";  onTriggered: root.themeChangeRequested("dark") }
            MenuItem { text: "Cálido";                 checkable: true; checked: root.themeName==="warm";  onTriggered: root.themeChangeRequested("warm") }
            MenuItem { text: "Neón";                   checkable: true; checked: root.themeName==="neon";  onTriggered: root.themeChangeRequested("neon") }
        }
        MenuSeparator {}
        MenuItem { text: "Opciones de carpeta…" }
    }

    Menu {
        id: _ayudaMenu
        palette.window: root.pal.panel; palette.windowText: root.pal.text
        palette.highlight: root.pal.accentSoft; palette.highlightedText: root.pal.accent
        MenuItem { text: "Ver ayuda"; onTriggered: root.helpRequested() }
        MenuSeparator {}
        MenuItem { text: "Acerca de Win7 Explorer"; onTriggered: root.aboutRequested() }
    }
}
