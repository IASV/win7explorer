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
        anchors.topMargin: 2;   anchors.bottomMargin: 2
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

        Label {
            visible: root.selectedCount === 1
            text: root.selItem ? root.selItem.name : ""
            color: root.pal.text; font.pixelSize: 11; font.bold: true
            elide: Text.ElideRight; Layout.fillWidth: true
        }
    }
}
