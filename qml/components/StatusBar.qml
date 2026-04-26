import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var pal
    property int selectedCount: 0
    property int itemCount:     0
    property var selItem: null

    border.color: pal.borderSoft
    gradient: Gradient {
        GradientStop { position: 0; color: pal.stat1 }
        GradientStop { position: 1; color: pal.stat2 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10; anchors.rightMargin: 10
        anchors.topMargin: 4;   anchors.bottomMargin: 4
        spacing: 10

        Label {
            visible: root.selectedCount === 0
            text: root.itemCount + " elemento" + (root.itemCount === 1 ? "" : "s")
            color: root.pal.muted; font.pixelSize: 11
        }
        Label {
            visible: root.selectedCount > 1
            text: root.selectedCount + " elementos seleccionados"
            color: root.pal.muted; font.pixelSize: 11
        }

        Image {
            visible: root.selectedCount === 1
            source: root.selItem ? (root.selItem.iconSrc || "") : ""
            Layout.preferredWidth: 32; Layout.preferredHeight: 32
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            visible: root.selectedCount === 1
            Layout.fillWidth: true; spacing: 2

            Label {
                text: root.selItem ? root.selItem.name : ""
                color: root.pal.text; font.pixelSize: 12; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            RowLayout {
                spacing: 12
                Repeater {
                    model: {
                        var it = root.selItem; if (!it) return []
                        var parts = [{ lbl: "Tipo", val: it.typeStr || "" }]
                        if (it.modified) parts.push({ lbl: "Modificado", val: it.modified })
                        if (it.size)     parts.push({ lbl: "Tamaño",     val: it.size })
                        return parts
                    }
                    delegate: Row {
                        spacing: 4
                        Label { text: modelData.lbl+":"; color: root.pal.muted; font.pixelSize: 11 }
                        Label { text: modelData.val;     color: root.pal.text;  font.pixelSize: 11 }
                    }
                }
            }
        }
    }
}
