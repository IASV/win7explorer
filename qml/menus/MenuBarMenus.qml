import QtQuick
import QtQuick.Controls

// Container that holds and exposes the 5 Win7 menu-bar menus.
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
    property string language:         "es"

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
    signal connectDriveRequested
    signal disconnectDriveRequested
    signal terminalRequested
    signal helpRequested
    signal aboutRequested
    signal languageChangeRequested(string lang)

    property alias archivoMenu:      _archivoMenu
    property alias edicionMenu:      _edicionMenu
    property alias verMenu:          _verMenu
    property alias herramientasMenu: _herramientasMenu
    property alias ayudaMenu:        _ayudaMenu

    // ── Shared Win7 background component ──────────────────────────────────
    component W7Bg: Rectangle {
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

    // ── Menus ──────────────────────────────────────────────────────────────

    Menu {
        id: _archivoMenu
        background: W7Bg {}
        W7Item { text: I18n.t("Nueva carpeta");  onTriggered: root.newFolderRequested() }
        W7Sep {}
        W7Item { text: I18n.t("Eliminar");       enabled: root.selectedCount > 0;   onTriggered: root.deleteRequested() }
        W7Item { text: I18n.t("Cambiar nombre"); enabled: root.selectedCount === 1; onTriggered: root.renameRequested() }
        W7Item { text: I18n.t("Propiedades");    enabled: root.selectedCount > 0;   onTriggered: root.propertiesRequested() }
        W7Sep {}
        W7Item { text: I18n.t("Cerrar"); onTriggered: root.closeRequested() }
    }

    Menu {
        id: _edicionMenu
        background: W7Bg {}
        W7Item { text: I18n.t("Deshacer"); enabled: false }
        W7Item { text: I18n.t("Rehacer");  enabled: false }
        W7Sep {}
        W7Item { text: I18n.t("Cortar"); enabled: root.selectedCount > 0; onTriggered: root.cutRequested() }
        W7Item { text: I18n.t("Copiar"); enabled: root.selectedCount > 0; onTriggered: root.copyRequested() }
        W7Item { text: I18n.t("Pegar");  onTriggered: root.pasteRequested() }
        W7Sep {}
        W7Item { text: I18n.t("Copiar a la carpeta…"); enabled: root.selectedCount > 0; onTriggered: root.copyToFolderRequested() }
        W7Item { text: I18n.t("Mover a la carpeta…");  enabled: root.selectedCount > 0; onTriggered: root.moveToFolderRequested() }
        W7Sep {}
        W7Item { text: I18n.t("Seleccionar todo");   onTriggered: root.selectAllRequested() }
        W7Item { text: I18n.t("Invertir selección"); onTriggered: root.invertSelectionRequested() }
    }

    Menu {
        id: _verMenu
        background: W7Bg {}
        Menu {
            title: I18n.t("Vista")
            background: W7Bg {}
            W7Item { text: I18n.t("Iconos grandes");  checkable: true; checked: root.viewMode==="large";   onTriggered: root.viewModeChangeRequested("large") }
            W7Item { text: I18n.t("Iconos medianos"); checkable: true; checked: root.viewMode==="medium";  onTriggered: root.viewModeChangeRequested("medium") }
            W7Item { text: I18n.t("Lista");           checkable: true; checked: root.viewMode==="list";    onTriggered: root.viewModeChangeRequested("list") }
            W7Item { text: I18n.t("Detalles");        checkable: true; checked: root.viewMode==="details"; onTriggered: root.viewModeChangeRequested("details") }
            W7Item { text: I18n.t("Contenido");       checkable: true; checked: root.viewMode==="content"; onTriggered: root.viewModeChangeRequested("content") }
        }
        Menu {
            title: I18n.t("Ordenar por")
            background: W7Bg {}
            W7Item { text: I18n.t("Nombre");                onTriggered: root.sortRequested("name") }
            W7Item { text: I18n.t("Fecha de modificación"); onTriggered: root.sortRequested("modified") }
            W7Item { text: I18n.t("Tipo");                  onTriggered: root.sortRequested("type") }
            W7Item { text: I18n.t("Tamaño");                onTriggered: root.sortRequested("size") }
        }
        W7Sep {}
        Menu {
            title: I18n.t("Organizar")
            background: W7Bg {}
            Menu {
                title: I18n.t("Diseño")
                background: W7Bg {}
                W7Item { text: I18n.t("Barra de menús");        checkable: true; checked: root.showMenuBar;      onTriggered: root.menuBarToggled() }
                W7Item { text: I18n.t("Panel de detalles");     checkable: true; checked: root.showDetailsPanel; onTriggered: root.detailsPanelToggled() }
                W7Item { text: I18n.t("Panel de vista previa"); checkable: true; checked: root.showPreview;      onTriggered: root.previewToggled() }
                W7Item { text: I18n.t("Panel de navegación");   checkable: true; checked: root.showSidebar;      onTriggered: root.sidebarToggled() }
                W7Sep {}
                W7Item { text: I18n.t("Barra de estado"); checkable: true; checked: root.showStatusBar; onTriggered: root.statusBarToggled() }
            }
        }
        W7Sep {}
        W7Item { text: I18n.t("Actualizar"); onTriggered: root.refreshRequested() }
    }

    Menu {
        id: _herramientasMenu
        background: W7Bg {}
        W7Item { text: I18n.t("Conectar a unidad de red…");     onTriggered: root.connectDriveRequested() }
        W7Item { text: I18n.t("Desconectar de unidad de red…"); onTriggered: root.disconnectDriveRequested() }
        W7Sep {}
        W7Item { text: I18n.t("Abrir símbolo del sistema"); onTriggered: root.terminalRequested() }
        W7Sep {}
        Menu {
            title: I18n.t("Tema")
            background: W7Bg {}
            W7Item { text: I18n.t("Glass (predeterminado)"); checkable: true; checked: root.themeName==="glass"; onTriggered: root.themeChangeRequested("glass") }
            W7Item { text: I18n.t("Plano");                  checkable: true; checked: root.themeName==="flat";  onTriggered: root.themeChangeRequested("flat") }
            W7Item { text: I18n.t("Oscuro");                 checkable: true; checked: root.themeName==="dark";  onTriggered: root.themeChangeRequested("dark") }
            W7Item { text: I18n.t("Cálido");                 checkable: true; checked: root.themeName==="warm";  onTriggered: root.themeChangeRequested("warm") }
            W7Item { text: I18n.t("Neón");                   checkable: true; checked: root.themeName==="neon";  onTriggered: root.themeChangeRequested("neon") }
        }
        Menu {
            title: I18n.t("Elegir idioma")
            background: W7Bg {}
            W7Item { text: I18n.t("Español"); checkable: true; checked: root.language==="es"; onTriggered: root.languageChangeRequested("es") }
            W7Item { text: I18n.t("Inglés");  checkable: true; checked: root.language==="en"; onTriggered: root.languageChangeRequested("en") }
        }
        W7Sep {}
        W7Item { text: I18n.t("Opciones de carpeta…") }
    }

    Menu {
        id: _ayudaMenu
        background: W7Bg {}
        W7Item { text: I18n.t("Ver ayuda"); onTriggered: root.helpRequested() }
        W7Sep {}
        W7Item { text: I18n.t("Acerca de Win7 Explorer"); onTriggered: root.aboutRequested() }
    }
}
