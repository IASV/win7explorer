import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var pal
    property var previewItem: null

    color: pal.panel
    border.color: pal.borderSoft

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Hero icon or placeholder
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 180

            Column {
                visible: root.previewItem === null
                anchors.centerIn: parent
                spacing: 10
                Canvas {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 48; height: 48
                    property color fg: root.pal.muted
                    onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,48,48)
                        ctx.strokeStyle=fg; ctx.globalAlpha=0.4; ctx.lineWidth=1.2
                        ctx.strokeRect(8,6,32,36)
                        ctx.beginPath(); ctx.moveTo(16,16); ctx.lineTo(32,16)
                        ctx.moveTo(16,22); ctx.lineTo(32,22); ctx.moveTo(16,28); ctx.lineTo(26,28); ctx.stroke()
                    }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Selecciona un archivo\npara previsualizar"
                    color: root.pal.muted; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12
                }
            }

            Image {
                visible: root.previewItem !== null
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: root.previewItem ? (root.previewItem.previewSrc || root.previewItem.iconSrc || "") : ""
            }
        }

        Label {
            visible: root.previewItem !== null
            Layout.fillWidth: true
            text: root.previewItem ? root.previewItem.name : ""
            color: root.pal.text; font.pixelSize: 12; font.bold: true
            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
        }

        Label {
            visible: root.previewItem !== null
            Layout.fillWidth: true
            text: root.previewItem ? (root.previewItem.typeStr || "") : ""
            color: root.pal.muted; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
        }

        Column {
            visible: root.previewItem !== null
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: {
                    var it = root.previewItem; if (!it) return []
                    var rows = []
                    if (it.modified) rows.push({ lbl: "Modificado", val: it.modified })
                    if (it.size)     rows.push({ lbl: "Tamaño",     val: it.size })
                    if (it.dim)      rows.push({ lbl: "Dimensiones",val: it.dim })
                    if (it.duration) rows.push({ lbl: "Duración",   val: it.duration })
                    return rows
                }
                delegate: RowLayout {
                    width: parent.width
                    Label { text: modelData.lbl+":"; color: root.pal.muted; font.pixelSize: 11; Layout.preferredWidth: 80 }
                    Label { text: modelData.val;     color: root.pal.text;  font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
