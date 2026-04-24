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

    Rectangle {
        width: parent.width
        height: 22
        color: siRoot.currentId === siRoot.item.id
               ? siRoot.pal.sbCurrent
               : (siHover.containsMouse ? siRoot.pal.sbHover : "transparent")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 + siRoot.level * 14
            spacing: 4

            Label {
                text: siRoot.item.children && siRoot.item.children.length > 0
                      ? (siRoot.expanded ? "▼" : "▶") : " "
                color: siRoot.pal.muted
                font.pixelSize: 8
                MouseArea {
                    anchors.fill: parent
                    onClicked: siRoot.expanded = !siRoot.expanded
                }
            }

            Image {
                source: siRoot.fs ? siRoot.fs.iconFor(siRoot.item) : ""
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: siRoot.item.name
                color: siRoot.pal.sbText
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: siHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (siRoot.navigateFn) siRoot.navigateFn(siRoot.item.id)
            onDoubleClicked: siRoot.expanded = !siRoot.expanded
        }
    }

    // Loader breaks the compile-time recursion cycle.
    // Items are resolved at runtime, after SidebarItem.qml is fully loaded.
    Repeater {
        model: siRoot.expanded && siRoot.item.children
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
