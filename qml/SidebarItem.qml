import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: siRoot
    property var item
    property int level: 0
    property bool expanded: false
    property var pal
    property var fs
    property string currentId: ""
    property var navigateFn

    spacing: 0

    property bool isCurrent: siRoot.item && siRoot.item.id === siRoot.currentId
    property bool hasChildren: siRoot.item && siRoot.item.children
        ? siRoot.item.children.filter(function(c){ return c.type !== "file" }).length > 0
        : false

    Rectangle {
        width: parent.width
        height: 22
        color: siRoot.isCurrent ? siRoot.pal.sbCurrent
             : (sbHov.containsMouse ? siRoot.pal.sbHover : "transparent")

        // border-left indicator for current item
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: siRoot.isCurrent ? siRoot.pal.selectionBorder : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 2 + siRoot.level * 14 + 10
            anchors.rightMargin: 6
            spacing: 6

            // Rotating chevron (hidden when no children)
            Item {
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
                rotation: siRoot.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 120 } }
                opacity: siRoot.hasChildren ? 1 : 0

                Canvas {
                    anchors.fill: parent
                    property color fg: siRoot.pal ? siRoot.pal.muted : "#888"
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
                source: siRoot.fs ? siRoot.fs.iconFor(siRoot.item) : ""
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: siRoot.item ? siRoot.item.name : ""
                color: siRoot.isCurrent ? siRoot.pal.selText : siRoot.pal.sbText
                font.pixelSize: 12
                font.bold: siRoot.isCurrent
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: sbHov
            anchors.fill: parent
            hoverEnabled: true
            onClicked: (mouse) => {
                var chevLeft = 2 + siRoot.level * 14 + 10
                if (siRoot.hasChildren && mouse.x >= chevLeft && mouse.x < chevLeft + 20) {
                    siRoot.expanded = !siRoot.expanded
                } else {
                    if (siRoot.navigateFn) siRoot.navigateFn(siRoot.item.id)
                }
            }
            onDoubleClicked: {
                if (siRoot.hasChildren) siRoot.expanded = !siRoot.expanded
            }
        }
    }

    Repeater {
        model: siRoot.expanded && siRoot.item && siRoot.item.children
               ? siRoot.item.children.filter(function(c) { return c.type !== "file" })
               : []
        delegate: Loader {
            width: siRoot.width
            source: "SidebarItem.qml"
            onLoaded: {
                item.item = modelData
                item.level = siRoot.level + 1
                item.fs = siRoot.fs
                item.navigateFn = siRoot.navigateFn
                item.pal = Qt.binding(function() { return siRoot.pal })
                item.currentId = Qt.binding(function() { return siRoot.currentId })
            }
        }
    }
}
