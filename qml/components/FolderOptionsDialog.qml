import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var  pal
    property bool showHiddenFiles: false

    title:         "Opciones de carpeta"
    width:         380
    height:        200
    minimumWidth:  320
    minimumHeight: 180
    modality:      Qt.ApplicationModal
    flags:         Qt.Dialog

    signal optionsChanged(bool showHidden)

    function open() {
        showHiddenCheckbox.checked = root.showHiddenFiles
        visible = true
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
            spacing:         6

            Label {
                text:           "General"
                font.pixelSize: 11
                font.bold:      true
                color:          root.pal ? root.pal.text : "#000"
            }

            Rectangle {
                Layout.fillWidth: true
                height:           1
                color:            root.pal ? root.pal.border : "#c0c0c0"
            }

            CheckBox {
                id:             showHiddenCheckbox
                text:           "Mostrar archivos y carpetas ocultos"
                font.pixelSize: 11
                checked:        root.showHiddenFiles
            }

            CheckBox {
                text:           "Mostrar archivos del sistema operativo"
                font.pixelSize: 11
                enabled:        false
                opacity:        0.5
                ToolTip.visible: hovered
                ToolTip.text:    "Próximamente"
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                height:           1
                color:            root.pal ? root.pal.border : "#c0c0c0"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing:          6

                Item { Layout.fillWidth: true }

                Button {
                    text:      "Aceptar"

                    onClicked: {
                        root.optionsChanged(showHiddenCheckbox.checked)
                        root.close()
                    }
                }

                Button {
                    text:      "Cancelar"
                    onClicked: root.close()
                }
            }
        }
    }
}
