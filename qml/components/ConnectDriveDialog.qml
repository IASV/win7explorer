import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var pal

    title:    (I18n.lang, I18n.t("Conectar a unidad de red"))
    width:    440
    height:   160
    modality: Qt.ApplicationModal
    flags:    Qt.Dialog

    signal connectRequested(string uri)

    function open() {
        uriField.text = ""
        visible = true
        uriField.forceActiveFocus()
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
                text:           (I18n.lang, I18n.t("Dirección del servidor:"))
                font.pixelSize: 11
                color:          root.pal ? root.pal.text : "#000"
            }

            TextField {
                id:                  uriField
                Layout.fillWidth:    true
                placeholderText:     "smb://servidor/recurso"
                font.pixelSize:      11
                Keys.onReturnPressed: {
                    if (connectButton.enabled) {
                        root.connectRequested(uriField.text.trim())
                        root.close()
                    }
                }
            }

            Label {
                text:           (I18n.lang, I18n.t("Protocolos: smb:// · sftp:// · ftp:// · dav:// · nfs://"))
                font.pixelSize: 10
                color:          root.pal ? root.pal.muted : "#888"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing:          6

                Item { Layout.fillWidth: true }

                Button {
                    id:        connectButton
                    text:      (I18n.lang, I18n.t("Conectar"))

                    enabled:   uriField.text.indexOf("://") !== -1
                    onClicked: {
                        root.connectRequested(uriField.text.trim())
                        root.close()
                    }
                }

                Button {
                    text:      (I18n.lang, I18n.t("Cancelar"))
                    onClicked: root.close()
                }
            }
        }
    }
}
