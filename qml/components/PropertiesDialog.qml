import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var pal
    property var item:      null
    property var fileProps: ({})

    title:      item ? ("Propiedades: " + (item.name || "")) : "Propiedades"
    width:      420
    height:     545
    minimumWidth:  400
    minimumHeight: 500
    modality:   Qt.ApplicationModal
    flags:      Qt.Dialog

    onVisibleChanged: {
        if (visible && root.item && root.item.id && root.item.id.startsWith('/'))
            root.fileProps = fsBackend.getFileProperties(root.item.id)
        else if (visible)
            root.fileProps = {}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // ── Icon + name ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; Layout.bottomMargin: 4
            spacing: 10
            Image {
                source: root.item ? (root.item.iconSrc || "") : ""
                sourceSize: Qt.size(32, 32)
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                fillMode: Image.PreserveAspectFit
            }
            Label {
                text: root.item ? (root.item.name || "") : ""
                font.pixelSize: 13; font.bold: true
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Tipo + Se abre con ─────────────────────────────────────
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 4
            Layout.fillWidth: true

            Label { text: "Tipo de archivo:"; font.pixelSize: 11; color: "#555" }
            Label { text: root.fileProps.type || root.item?.typeStr || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

            Label { visible: !(root.fileProps.isDir || false); text: "Se abre con:"; font.pixelSize: 11; color: "#555" }
            Label { visible: !(root.fileProps.isDir || false); text: "Aplicación predeterminada"; font.pixelSize: 11; Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Ubicación + tamaños ────────────────────────────────────
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 4
            Layout.fillWidth: true

            Label { text: "Ubicación:"; font.pixelSize: 11; color: "#555" }
            Label { text: root.fileProps.location || ""; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }

            Label { visible: !(root.fileProps.isDir || false); text: "Tamaño:"; font.pixelSize: 11; color: "#555" }
            Label {
                visible: !(root.fileProps.isDir || false)
                text: root.fileProps.sizeFormatted
                      ? (root.fileProps.sizeFormatted + " (" + root.fileProps.size + " bytes)")
                      : ""
                font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
            }

            Label { visible: !(root.fileProps.isDir || false); text: "Tamaño en disco:"; font.pixelSize: 11; color: "#555" }
            Label {
                visible: !(root.fileProps.isDir || false)
                text: root.fileProps.diskSizeFormatted
                      ? (root.fileProps.diskSizeFormatted + " (" + root.fileProps.diskSize + " bytes)")
                      : ""
                font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Fechas ─────────────────────────────────────────────────
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 4
            Layout.fillWidth: true

            Label { text: "Creado:";        font.pixelSize: 11; color: "#555" }
            Label { text: root.fileProps.created  || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

            Label { text: "Modificado:";    font.pixelSize: 11; color: "#555" }
            Label { text: root.fileProps.modified || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

            Label { text: "Último acceso:"; font.pixelSize: 11; color: "#555" }
            Label { text: root.fileProps.accessed || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Atributos ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 16
            Label { text: "Atributos:"; font.pixelSize: 11; color: "#555" }
            CheckBox { text: "Sólo lectura"; checked: root.fileProps.readonly || false; font.pixelSize: 11; enabled: false }
            CheckBox { text: "Oculto";       checked: root.fileProps.hidden   || false; font.pixelSize: 11; enabled: false }
        }

        Item { Layout.fillHeight: true }

        // ── Buttons ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button { text: "Aceptar";   onClicked: root.close() }
            Button { text: "Cancelar";  onClicked: root.close() }
            Button { text: "Aplicar";   enabled: false }
        }
    }
}
