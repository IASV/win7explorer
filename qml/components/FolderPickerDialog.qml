import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var    pal
    property string operation: "copy"

    title:    (i18n.lang, i18n.t("Seleccionar carpeta de destino"))
    width:    420
    height:   110
    modality: Qt.ApplicationModal
    flags:    Qt.Dialog

    signal folderSelected(string destPath, string operation)

    function open(suggestedPath) {
        destField.text = suggestedPath || ""
        visible = true
        destField.forceActiveFocus()
    }
    function close() { visible = false }

    Rectangle {
        anchors.fill: parent
        color:        root.pal ? root.pal.panel  : "#f0f0f0"
        border.color: root.pal ? root.pal.border : "#999"
        border.width: 1

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 16
            spacing:         8

            Label {
                text:           (i18n.lang, root.operation === "move"
                                    ? i18n.t("Mover a:")
                                    : i18n.t("Copiar a:"))
                font.pixelSize: 11
                color:          root.pal ? root.pal.text : "#000"
            }

            TextField {
                id:               destField
                Layout.fillWidth: true
                placeholderText:  "/ruta/a/carpeta"
                font.pixelSize:   11
                Keys.onReturnPressed: {
                    if (selectButton.enabled) {
                        root.folderSelected(destField.text.trim(), root.operation)
                        root.close()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing:          6

                Item { Layout.fillWidth: true }

                Button {
                    id:        selectButton
                    text:      (i18n.lang, i18n.t("Seleccionar"))

                    enabled:   destField.text.charAt(0) === "/"
                    onClicked: {
                        root.folderSelected(destField.text.trim(), root.operation)
                        root.close()
                    }
                }

                Button {
                    text:      (i18n.lang, i18n.t("Cancelar"))
                    onClicked: root.close()
                }
            }
        }
    }
}
