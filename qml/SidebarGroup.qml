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
        color: sgHover.containsMouse ? sgRoot.pal.sbHover : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            spacing: 6

            Label {
                text: sgRoot.expanded ? "▼" : "▶"
                color: sgRoot.pal.muted
                font.pixelSize: 9
            }

            Image {
                source: sgRoot.fs.iconForGroup(sgRoot.group.kind)
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
            id: sgHover
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
