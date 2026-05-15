import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    property var pal

    title:         (I18n.lang, I18n.t("Acerca de Win7 Explorer"))
    width:         480
    height:        620
    minimumWidth:  440
    minimumHeight: 560
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
                    text: (I18n.lang, I18n.t("Win7 Explorer"))
                    font.pixelSize: 18; font.bold: true
                    color: root.pal ? root.pal.text : "#000"
                }
                Label {
                    text: (I18n.lang, I18n.t("Explorador de archivos estilo Windows 7 para Linux"))
                    font.pixelSize: 11
                    color: root.pal ? root.pal.muted : "#666"
                    wrapMode: Text.Wrap; Layout.fillWidth: true
                }
                Label {
                    text: (I18n.lang, I18n.t("Versión 1.0.0"))
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
                text: (I18n.lang, I18n.t("Desarrollado por"))
                font.pixelSize: 11; font.bold: true
                color: root.pal ? root.pal.text : "#000"
            }

            GridLayout {
                columns: 2; columnSpacing: 10; rowSpacing: 4
                Layout.fillWidth: true

                Label { text: (I18n.lang, I18n.t("Director del proyecto:")); font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "IASUAREZ";               font.pixelSize: 11; color: root.pal ? root.pal.text  : "#000"; font.bold: true }

                Label { text: (I18n.lang, I18n.t("Herramienta de desarrollo:")); font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "Claude Code (Anthropic)";    font.pixelSize: 11; color: root.pal ? root.pal.text  : "#000" }

                Label { text: (I18n.lang, I18n.t("Diseño de interfaz:"));   font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "Claude Design (Anthropic)"; font.pixelSize: 11; color: root.pal ? root.pal.text : "#000" }

                Label { text: (I18n.lang, I18n.t("Tecnologías:")); font.pixelSize: 11; color: root.pal ? root.pal.muted : "#666" }
                Label { text: "Qt 6 / QML · C++ · Linux"; font.pixelSize: 11; color: root.pal ? root.pal.text : "#000" }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Licencia ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: (I18n.lang, I18n.t("Licencia"))
                font.pixelSize: 11; font.bold: true
                color: root.pal ? root.pal.text : "#000"
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 10
                color: root.pal ? root.pal.muted : "#666"
                text:
                    (I18n.lang, I18n.t("Distribuido bajo la licencia MIT. Puedes usar, copiar, modificar y ")) +
                    I18n.t("distribuir este software libremente. Este repositorio es de solo lectura: ") +
                    I18n.t("no se aceptan pull requests, issues ni contribuciones externas.")
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#c0c0c0" }

        // ── Aviso legal ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: (I18n.lang, I18n.t("Aviso legal"))
                font.pixelSize: 11; font.bold: true
                color: root.pal ? root.pal.text : "#000"
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font.pixelSize: 10
                color: root.pal ? root.pal.muted : "#666"
                text:
                    (I18n.lang, I18n.t("ESTE SOFTWARE SE PROPORCIONA «TAL CUAL», SIN GARANTÍA DE NINGÚN TIPO. ")) +
                    I18n.t("El autor (IASUAREZ) no se hace responsable de ningún daño al sistema, ") +
                    I18n.t("pérdida de datos ni problema que pueda derivarse de su uso. ") +
                    I18n.t("Úsalo bajo tu propia responsabilidad.\n\n") +
                    I18n.t("Windows 7 y Windows Explorer son marcas registradas de Microsoft Corporation. ") +
                    I18n.t("Win7 Explorer es una adaptación visual independiente y de código abierto, ") +
                    I18n.t("sin afiliación ni respaldo de Microsoft Corporation.\n\n") +
                    "© 2026 IASUAREZ"
            }
        }

        Item { Layout.fillHeight: true }

        // ── Botón cerrar ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button {
                text: (I18n.lang, I18n.t("Cerrar"))
                onClicked: root.close()
            }
        }
    }
}
