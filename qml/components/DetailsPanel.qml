import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var    pal
    property var    detailItem:        null
    property int    selectedCount:     0
    property bool   useGroupedView:    false
    property string currentKind:       ""
    property var    systemInfo:        null
    property string currentFolderName: ""
    property int    currentItemCount:  0
    property string totalSelectedSize: ""

    readonly property bool computerMode:
        root.useGroupedView && root.currentKind === "computer" && root.selectedCount === 0

    color: pal.panel
    border.color: pal.borderSoft

    // ── Computer / Equipo info bar ─────────────────────────────────────────
    RowLayout {
        visible: root.computerMode
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 8;   anchors.bottomMargin: 8
        spacing: 14

        Image {
            source: "qrc:/icons/window.png"
            Layout.preferredWidth: 48; Layout.preferredHeight: 48
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            spacing: 3

            Label {
                text: root.systemInfo ? root.systemInfo.hostname : ""
                color: root.pal.text
                font.pixelSize: 13; font.bold: true
            }
            Label {
                text: root.systemInfo ? root.systemInfo.osVersion : ""
                color: root.pal.muted
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: root.pal.border
            opacity: 0.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Label {
                text: root.systemInfo ? ("Memoria: " + root.systemInfo.ramFormatted) : ""
                color: root.pal.text
                font.pixelSize: 11
            }
            Label {
                text: root.systemInfo ? ("Procesador: " + root.systemInfo.cpuModel) : ""
                color: root.pal.muted
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // ── Normal file info bar ───────────────────────────────────────────────
    RowLayout {
        visible: !root.computerMode
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 10;  anchors.bottomMargin: 10
        spacing: 14

        // Icon: file icon when 1 item, generic canvas otherwise
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

            // No selection → current folder name + item count
            Label {
                visible: root.detailItem === null && root.selectedCount === 0
                text: root.currentFolderName
                color: root.pal.text; font.pixelSize: 13; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Label {
                visible: root.detailItem === null && root.selectedCount === 0
                text: root.currentItemCount + " elemento" + (root.currentItemCount === 1 ? "" : "s")
                color: root.pal.muted; font.pixelSize: 11
            }

            // Multi-selection
            Label {
                visible: root.selectedCount > 1
                text: root.selectedCount + " elementos seleccionados"
                color: root.pal.text; font.pixelSize: 13; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Label {
                visible: root.selectedCount > 1 && root.totalSelectedSize !== ""
                text: root.totalSelectedSize
                color: root.pal.muted; font.pixelSize: 11
            }

            // Single selection
            Label {
                visible: root.detailItem !== null
                text: root.detailItem ? root.detailItem.name : ""
                color: root.pal.text; font.pixelSize: 13; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            RowLayout {
                visible: root.detailItem !== null
                spacing: 18
                Label { text: root.detailItem ? (root.detailItem.typeStr || "") : ""; color: root.pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.size;     text: root.detailItem ? (root.detailItem.size || "") : ""; color: root.pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.modified; text: root.detailItem ? ("Modificado: " + (root.detailItem.modified || "")) : ""; color: root.pal.muted; font.pixelSize: 11 }
            }
        }
    }
}
