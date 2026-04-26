import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var pal
    property var detailItem: null

    color: pal.panel
    border.color: pal.borderSoft

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 10;  anchors.bottomMargin: 10
        spacing: 14

        Image {
            visible: root.detailItem !== null
            source: root.detailItem ? (root.detailItem.iconSrc || "") : ""
            Layout.preferredWidth: 48; Layout.preferredHeight: 48
            fillMode: Image.PreserveAspectFit
        }

        Canvas {
            visible: root.detailItem === null
            width: 48; height: 48
            property color fg: root.pal.muted
            onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0,0,48,48)
                ctx.strokeStyle=fg; ctx.globalAlpha=0.25; ctx.lineWidth=1.2
                ctx.strokeRect(8,5,28,38)
                ctx.beginPath(); ctx.moveTo(14,18); ctx.lineTo(30,18)
                ctx.moveTo(14,24); ctx.lineTo(30,24); ctx.moveTo(14,30); ctx.lineTo(24,30); ctx.stroke()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 4

            Label {
                text: root.detailItem ? root.detailItem.name : "Selecciona un archivo para ver sus detalles"
                color: root.detailItem ? root.pal.text : root.pal.muted
                font.pixelSize: 13; font.bold: root.detailItem !== null
                elide: Text.ElideRight; Layout.fillWidth: true
            }

            RowLayout {
                visible: root.detailItem !== null
                spacing: 18
                Label { text: root.detailItem ? (root.detailItem.typeStr || "")    : ""; color: root.pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && root.detailItem.size;     text: root.detailItem ? (root.detailItem.size     || "") : ""; color: root.pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && root.detailItem.modified; text: root.detailItem ? ("Modificado: " + (root.detailItem.modified || "")) : ""; color: root.pal.muted; font.pixelSize: 11 }
            }
        }
    }
}
