import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    property var pal
    property var item:      null
    property var fileProps: ({})

    title:   item ? ("Propiedades: " + (item.name || "")) : "Propiedades"
    modal:   true
    width:   420
    anchors.centerIn: parent
    standardButtons: Dialog.Ok | Dialog.Cancel

    background: Rectangle {
        color:        root.pal ? root.pal.panel : "#f0f0f0"
        border.color: root.pal ? root.pal.borderSoft : "#aaa"
        radius: 4
    }

    onAboutToShow: {
        if (root.item && root.item.id && root.item.id.startsWith('/'))
            root.fileProps = fsBackend.getFileProperties(root.item.id)
        else
            root.fileProps = {}
    }

    ColumnLayout {
        width: parent.width
        spacing: 0

        // ── Header: icon + name ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4; Layout.bottomMargin: 8
            spacing: 10

            Image {
                source: root.item ? (root.item.iconSrc || "") : ""
                sourceSize: Qt.size(32, 32)
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                fillMode: Image.PreserveAspectFit
            }
            Label {
                text:           root.item ? (root.item.name || "") : ""
                color:          root.pal ? root.pal.text : "#000"
                font.pixelSize: 13; font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.pal ? root.pal.borderSoft : "#ccc"; Layout.bottomMargin: 6 }

        // ── Tipo + Se abre con ─────────────────────────────────────────────
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 5
            Layout.fillWidth: true; Layout.bottomMargin: 6

            Label { text: "Tipo de archivo:"; color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label { text: root.fileProps.type || root.item?.typeStr || ""; color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

            Label { visible: !(root.fileProps.isDir || false); text: "Se abre con:"; color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label { visible: !(root.fileProps.isDir || false); text: "Aplicación predeterminada"; color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11; Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.pal ? root.pal.borderSoft : "#ccc"; Layout.bottomMargin: 6 }

        // ── Ubicación + tamaños ────────────────────────────────────────────
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 5
            Layout.fillWidth: true; Layout.bottomMargin: 6

            Label { text: "Ubicación:"; color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label {
                text: root.fileProps.location || ""
                color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11
                Layout.fillWidth: true; elide: Text.ElideRight
            }

            Label { visible: !(root.fileProps.isDir || false); text: "Tamaño:"; color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label {
                visible: !(root.fileProps.isDir || false)
                text: root.fileProps.sizeFormatted
                      ? (root.fileProps.sizeFormatted + " (" + root.fileProps.size + " bytes)")
                      : ""
                color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11
                Layout.fillWidth: true; wrapMode: Text.Wrap
            }

            Label { visible: !(root.fileProps.isDir || false); text: "Tamaño en disco:"; color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label {
                visible: !(root.fileProps.isDir || false)
                text: root.fileProps.diskSizeFormatted
                      ? (root.fileProps.diskSizeFormatted + " (" + root.fileProps.diskSize + " bytes)")
                      : ""
                color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11
                Layout.fillWidth: true; wrapMode: Text.Wrap
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.pal ? root.pal.borderSoft : "#ccc"; Layout.bottomMargin: 6 }

        // ── Fechas ─────────────────────────────────────────────────────────
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 5
            Layout.fillWidth: true; Layout.bottomMargin: 6

            Label { text: "Creado:";         color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label { text: root.fileProps.created  || ""; color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

            Label { text: "Modificado:";     color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label { text: root.fileProps.modified || ""; color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

            Label { text: "Último acceso:";  color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            Label { text: root.fileProps.accessed || ""; color: root.pal ? root.pal.text : "#000"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: root.pal ? root.pal.borderSoft : "#ccc"; Layout.bottomMargin: 6 }

        // ── Atributos ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: 2; Layout.bottomMargin: 4
            spacing: 16

            Label { text: "Atributos:"; color: root.pal ? root.pal.muted : "#666"; font.pixelSize: 11 }
            CheckBox {
                text: "Sólo lectura"
                checked: root.fileProps.readonly || false
                font.pixelSize: 11
                enabled: false
            }
            CheckBox {
                text: "Oculto"
                checked: root.fileProps.hidden || false
                font.pixelSize: 11
                enabled: false
            }
        }
    }
}
