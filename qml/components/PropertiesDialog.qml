import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var pal
    property var item:       null
    property var fileProps:  ({})
    property var driveProps: ({})

    readonly property bool isDrive: root.item && root.item.type === "drive"

    title: {
        var _l = I18n.lang
        if (item) return I18n.t("Propiedades: ") + (item.name || "")
        return I18n.t("Propiedades")
    }
    width:       420
    height:      isDrive ? 480 : 620
    minimumWidth:  400
    minimumHeight: isDrive ? 400 : 520
    modality:    Qt.ApplicationModal
    flags:       Qt.Dialog

    onVisibleChanged: {
        if (!visible) return
        if (!root.item || !root.item.id) { root.fileProps = {}; root.driveProps = {}; return }
        const path = root.item.id
        if (root.isDrive) {
            root.driveProps = FsBackend.getDriveProperties(path)
            root.fileProps  = {}
        } else if (path.startsWith('/')) {
            root.fileProps  = FsBackend.getFileProperties(path)
            root.driveProps = {}
        } else {
            root.fileProps  = {}; root.driveProps = {}
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // ── Icon + name ────────────────────────────────────────────────────
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
                font.pixelSize: 13
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ══════════════ DRIVE VIEW ════════════════════════════════════════
        ColumnLayout {
            visible: root.isDrive
            Layout.fillWidth: true
            spacing: 8

            // Space usage bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: "#e8e8e8"
                    border.color: "#aaa"
                    radius: 2
                    clip: true

                    Rectangle {
                        width: parent.width * Math.min(root.driveProps.usedRatio || 0, 1.0)
                        height: parent.height
                        radius: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#4a90d9" }
                            GradientStop { position: 1.0; color: "#1e6abf" }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: (I18n.lang, root.driveProps.usedFormatted
                              ? (root.driveProps.usedFormatted + " " + I18n.t("de") + " " + root.driveProps.totalFormatted)
                              : "")
                        font.pixelSize: 10
                        color: (root.driveProps.usedRatio || 0) > 0.5 ? "white" : "#333"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle { width: 12; height: 12; color: "#4a90d9"; border.color: "#aaa"; radius: 1 }
                    Label { text: (I18n.lang, I18n.t("Usado"));  font.pixelSize: 10; color: "#555"; Layout.fillWidth: true }
                    Rectangle { width: 12; height: 12; color: "#e8e8e8"; border.color: "#aaa"; radius: 1 }
                    Label { text: (I18n.lang, I18n.t("Libre")); font.pixelSize: 10; color: "#555" }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

            // Space details
            GridLayout {
                columns: 2; columnSpacing: 12; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: (I18n.lang, I18n.t("Espacio usado:"));     font.pixelSize: 11; color: "#555" }
                Label {
                    text: root.driveProps.usedFormatted
                          ? (root.driveProps.usedFormatted + "  (" + (root.driveProps.usedBytes || "") + ")")
                          : "N/D"
                    font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
                }

                Label { text: (I18n.lang, I18n.t("Espacio libre:"));     font.pixelSize: 11; color: "#555" }
                Label {
                    text: root.driveProps.freeFormatted
                          ? (root.driveProps.freeFormatted + "  (" + (root.driveProps.freeBytes || "") + ")")
                          : "N/D"
                    font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
                }

                Label { text: (I18n.lang, I18n.t("Capacidad:"));         font.pixelSize: 11; color: "#555" }
                Label {
                    text: root.driveProps.totalFormatted
                          ? (root.driveProps.totalFormatted + "  (" + (root.driveProps.totalBytes || "") + ")")
                          : "N/D"
                    font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

            // Drive info
            GridLayout {
                columns: 2; columnSpacing: 12; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: (I18n.lang, I18n.t("Punto de montaje:"));  font.pixelSize: 11; color: "#555" }
                Label { text: root.driveProps.mountPoint || ""; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }

                Label { text: (I18n.lang, I18n.t("Dispositivo:"));       font.pixelSize: 11; color: "#555" }
                Label { text: root.driveProps.device || ""; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }

                Label { text: (I18n.lang, I18n.t("Sistema de archivos:")); font.pixelSize: 11; color: "#555" }
                Label { text: (root.driveProps.fsType || "").toUpperCase() || ""; font.pixelSize: 11; Layout.fillWidth: true }

                Label { text: (I18n.lang, I18n.t("Etiqueta:"));          font.pixelSize: 11; color: "#555" }
                Label { text: root.driveProps.label || ""; font.pixelSize: 11; Layout.fillWidth: true }

                Label { text: (I18n.lang, I18n.t("Solo lectura:"));      font.pixelSize: 11; color: "#555" }
                Label { text: (I18n.lang, root.driveProps.isReadOnly ? I18n.t("Sí") : I18n.t("No")); font.pixelSize: 11 }
            }
        }

        // ══════════════ FILE / FOLDER VIEW ════════════════════════════════
        ColumnLayout {
            visible: !root.isDrive
            Layout.fillWidth: true
            spacing: 6

            // Tipo + Se abre con
            GridLayout {
                columns: 2; columnSpacing: 12; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: (I18n.lang, I18n.t("Tipo de archivo:")); font.pixelSize: 11; color: "#555" }
                Label { text: root.fileProps.type || root.item?.typeStr || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

                Label { visible: !(root.fileProps.isDir || false); text: (I18n.lang, I18n.t("Se abre con:")); font.pixelSize: 11; color: "#555" }
                Label { visible: !(root.fileProps.isDir || false); text: (I18n.lang, I18n.t("Aplicación predeterminada")); font.pixelSize: 11; Layout.fillWidth: true }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

            // Ubicación + tamaños
            GridLayout {
                columns: 2; columnSpacing: 12; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: (I18n.lang, I18n.t("Ubicación:")); font.pixelSize: 11; color: "#555" }
                Label { text: root.fileProps.location || ""; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }

                Label { visible: !(root.fileProps.isDir || false); text: (I18n.lang, I18n.t("Tamaño:")); font.pixelSize: 11; color: "#555" }
                Label {
                    visible: !(root.fileProps.isDir || false)
                    text: root.fileProps.sizeFormatted
                          ? (root.fileProps.sizeFormatted + " (" + root.fileProps.size + " bytes)")
                          : ""
                    font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
                }

                Label { visible: !(root.fileProps.isDir || false); text: (I18n.lang, I18n.t("Tamaño en disco:")); font.pixelSize: 11; color: "#555" }
                Label {
                    visible: !(root.fileProps.isDir || false)
                    text: root.fileProps.diskSizeFormatted
                          ? (root.fileProps.diskSizeFormatted + " (" + root.fileProps.diskSize + " bytes)")
                          : ""
                    font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

            // Fechas
            GridLayout {
                columns: 2; columnSpacing: 12; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: (I18n.lang, I18n.t("Creado:"));        font.pixelSize: 11; color: "#555" }
                Label { text: root.fileProps.created  || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

                Label { text: (I18n.lang, I18n.t("Modificado:"));    font.pixelSize: 11; color: "#555" }
                Label { text: root.fileProps.modified || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }

                Label { text: (I18n.lang, I18n.t("Último acceso:")); font.pixelSize: 11; color: "#555" }
                Label { text: root.fileProps.accessed || ""; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

            // Atributos
            RowLayout {
                Layout.fillWidth: true; spacing: 16
                Label { text: (I18n.lang, I18n.t("Atributos:")); font.pixelSize: 11; color: "#555" }
                CheckBox { text: (I18n.lang, I18n.t("Sólo lectura")); checked: root.fileProps.readonly || false; font.pixelSize: 11; enabled: false }
                CheckBox { text: (I18n.lang, I18n.t("Oculto"));       checked: root.fileProps.hidden   || false; font.pixelSize: 11; enabled: false }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

            // Permisos
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label { text: (I18n.lang, I18n.t("Permisos:")); font.pixelSize: 11; color: "#555" }

                GridLayout {
                    columns: 4; columnSpacing: 10; rowSpacing: 2

                    Label { text: "" }
                    Label { text: (I18n.lang, I18n.t("Lectura"));   font.pixelSize: 10; color: "#555"; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
                    Label { text: (I18n.lang, I18n.t("Escritura")); font.pixelSize: 10; color: "#555"; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
                    Label { text: (I18n.lang, I18n.t("Ejecución")); font.pixelSize: 10; color: "#555"; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }

                    Label { text: (I18n.lang, I18n.t("Propietario")); font.pixelSize: 11; color: "#555" }
                    CheckBox { id: ownerRead;   checked: root.fileProps.ownerRead  || false; font.pixelSize: 11 }
                    CheckBox { id: ownerWrite;  checked: root.fileProps.ownerWrite || false; font.pixelSize: 11 }
                    CheckBox { id: ownerExec;   checked: root.fileProps.ownerExec  || false; font.pixelSize: 11 }

                    Label { text: (I18n.lang, I18n.t("Grupo")); font.pixelSize: 11; color: "#555" }
                    CheckBox { id: groupRead;   checked: root.fileProps.groupRead  || false; font.pixelSize: 11 }
                    CheckBox { id: groupWrite;  checked: root.fileProps.groupWrite || false; font.pixelSize: 11 }
                    CheckBox { id: groupExec;   checked: root.fileProps.groupExec  || false; font.pixelSize: 11 }

                    Label { text: (I18n.lang, I18n.t("Otros")); font.pixelSize: 11; color: "#555" }
                    CheckBox { id: othersRead;  checked: root.fileProps.othersRead  || false; font.pixelSize: 11 }
                    CheckBox { id: othersWrite; checked: root.fileProps.othersWrite || false; font.pixelSize: 11 }
                    CheckBox { id: othersExec;  checked: root.fileProps.othersExec  || false; font.pixelSize: 11 }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Buttons ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button {
                text: (I18n.lang, I18n.t("Aceptar"))
                onClicked: { if (!root.isDrive) applyPermissions(); root.close() }
            }
            Button {
                text: (I18n.lang, I18n.t("Cancelar"))
                onClicked: root.close()
            }
            Button {
                text: (I18n.lang, I18n.t("Aplicar"))
                visible: !root.isDrive
                onClicked: applyPermissions()
            }
        }
    }

    function applyPermissions() {
        if (!root.item || !root.item.id || !root.item.id.startsWith('/')) return
        FsBackend.setFilePermissions(root.item.id, {
            ownerRead:   ownerRead.checked,
            ownerWrite:  ownerWrite.checked,
            ownerExec:   ownerExec.checked,
            groupRead:   groupRead.checked,
            groupWrite:  groupWrite.checked,
            groupExec:   groupExec.checked,
            othersRead:  othersRead.checked,
            othersWrite: othersWrite.checked,
            othersExec:  othersExec.checked
        })
    }
}
