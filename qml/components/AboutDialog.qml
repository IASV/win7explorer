import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var pal

    title:         "Acerca de Win7 Explorer"
    width:         480
    height:        540
    minimumWidth:  440
    minimumHeight: 480
    modality:      Qt.ApplicationModal
    flags:         Qt.Dialog

    function open()  { visible = true  }
    function close() { visible = false }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        // ── Header ────────────────────────────────────────────────────────
        RowLayout {
            spacing: 16
            Image {
                source: "image://fileicons/computer"
                sourceSize: Qt.size(48, 48)
                Layout.preferredWidth: 48; Layout.preferredHeight: 48
                fillMode: Image.PreserveAspectFit
            }
            ColumnLayout {
                spacing: 2
                Label {
                    text: "Win7 Explorer"
                    font.pixelSize: 18; font.bold: true
                    color: root.pal ? root.pal.text : "#000"
                }
                Label {
                    text: "Explorador de archivos estilo Windows 7 para Linux"
                    font.pixelSize: 11
                    color: root.pal ? root.pal.muted : "#666"
                    wrapMode: Text.Wrap; Layout.fillWidth: true
                }
                Label {
                    text: "Versión 1.0.0"
                    font.pixelSize: 11
                    color: root.pal ? root.pal.muted : "#666"
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Créditos ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Desarrollado por"
                font.pixelSize: 11; font.bold: true
                color: root.pal ? root.pal.text : "#000"
            }

            GridLayout {
                columns: 2; columnSpacing: 10; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: "Director del proyecto:"; font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "IASUAREZ";               font.pixelSize: 11; color: root.pal ? root.pal.text  : "#000"; font.bold: true }

                Label { text: "Herramienta de desarrollo:"; font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "Claude Code (Anthropic)";    font.pixelSize: 11; color: root.pal ? root.pal.text  : "#000" }

                Label { text: "Diseño de interfaz:";   font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "Claude Design (Anthropic)"; font.pixelSize: 11; color: root.pal ? root.pal.text : "#000" }

                Label { text: "Tecnologías:"; font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "Qt 6 / QML · C++ · Linux"; font.pixelSize: 11; color: root.pal ? root.pal.text : "#000" }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Aviso legal ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: "Aviso legal"
                font.pixelSize: 11; font.bold: true
                color: root.pal ? root.pal.text : "#000"
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 10
                color: root.pal ? root.pal.muted : "#666"
                text:
                    "Windows 7 y Windows Explorer son marcas registradas de Microsoft " +
                    "Corporation. Win7 Explorer es una adaptación visual independiente, " +
                    "de código abierto, inspirada en el diseño del Explorador de Windows 7. " +
                    "Este proyecto no tiene afiliación, patrocinio ni respaldo oficial " +
                    "por parte de Microsoft Corporation.\n\n" +
                    "Todos los derechos sobre Windows, Windows Explorer y su interfaz " +
                    "gráfica pertenecen a Microsoft Corporation. Win7 Explorer no pretende " +
                    "reemplazar, competir ni infringir ningún producto o marca de Microsoft. " +
                    "Los iconos del sistema operativo utilizados pertenecen a sus respectivos " +
                    "autores.\n\n" +
                    "© IASUAREZ. Todos los derechos reservados."
            }
        }

        Item { Layout.fillHeight: true }

        // ── Botón cerrar ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button {
                text: "Cerrar"
                onClicked: root.close()
            }
        }
    }
}
