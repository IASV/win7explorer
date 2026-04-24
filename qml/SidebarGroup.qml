import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: sgRoot
    property var group
    property bool expanded: true
    property var pal
    property var fs
    property string currentId: ""
    property var navigateFn

    spacing: 0

    Rectangle {
        width: parent.width
        height: 24
        color: sgHov.containsMouse ? sgRoot.pal.sbHover : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            // Rotating chevron
            Item {
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
                rotation: sgRoot.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 120 } }

                Canvas {
                    anchors.fill: parent
                    property color fg: sgRoot.pal ? sgRoot.pal.muted : "#888"
                    onFgChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, 12, 12)
                        ctx.strokeStyle = fg
                        ctx.lineWidth = 1.4
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"
                        ctx.beginPath()
                        ctx.moveTo(3, 1.5)
                        ctx.lineTo(9, 6)
                        ctx.lineTo(3, 10.5)
                        ctx.stroke()
                    }
                }
            }

            Image {
                source: sgRoot.fs ? sgRoot.fs.iconForGroup(sgRoot.group.kind) : ""
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: sgRoot.group.name
                color: sgRoot.pal.sbText
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
            }
        }

        MouseArea {
            id: sgHov
            anchors.fill: parent
            hoverEnabled: true
            onClicked: sgRoot.expanded = !sgRoot.expanded
        }
    }

    Repeater {
        model: sgRoot.expanded ? sgRoot.group.children : []
        delegate: SidebarItem {
            item: modelData
            level: 0
            width: sgRoot.width
            pal: sgRoot.pal
            fs: sgRoot.fs
            currentId: sgRoot.currentId
            navigateFn: sgRoot.navigateFn
        }
    }
}
