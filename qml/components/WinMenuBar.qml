import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var pal

    signal archivoClicked
    signal edicionClicked
    signal verClicked
    signal herramientasClicked
    signal ayudaClicked

    color: pal.tbar1
    border.color: pal.borderSoft

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6; anchors.rightMargin: 6
        spacing: 0

        Repeater {
            model: [
                { title: "Archivo",      sig: "archivo" },
                { title: "Edición",      sig: "edicion" },
                { title: "Ver",          sig: "ver" },
                { title: "Herramientas", sig: "herramientas" },
                { title: "Ayuda",        sig: "ayuda" }
            ]
            delegate: Rectangle {
                implicitWidth:  mbLbl.implicitWidth + 16
                implicitHeight: 22
                color: mbMa.containsMouse ? root.pal.accentSoft : "transparent"
                border.color: mbMa.containsMouse ? root.pal.border : "transparent"
                radius: 2

                Label {
                    id: mbLbl
                    anchors.centerIn: parent
                    text: modelData.title
                    color: root.pal.text; font.pixelSize: 12
                }
                MouseArea {
                    id: mbMa
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if      (modelData.sig === "archivo")       root.archivoClicked()
                        else if (modelData.sig === "edicion")       root.edicionClicked()
                        else if (modelData.sig === "ver")           root.verClicked()
                        else if (modelData.sig === "herramientas")  root.herramientasClicked()
                        else if (modelData.sig === "ayuda")         root.ayudaClicked()
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
}
