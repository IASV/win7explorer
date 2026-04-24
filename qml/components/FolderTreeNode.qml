import QtQuick
import QtQuick.Layouts
import "../styles/Win7Theme.js" as Win7Theme

// Recursive folder tree node — used by NavigationPanel for the Equipo section.
// Children are loaded lazily on first expand; auto-expands when navigating into a child path.
Item {
    id: treeNode

    property string nodePath: ""
    property string nodeName: ""
    property int depth: 0
    property bool nodeHasChildren: false
    property bool expanded: false
    property var loadedChildren: []

    width: parent ? parent.width : 200
    implicitHeight: rowRect.height + (expanded ? childCol.implicitHeight : 0)
    height: implicitHeight

    function loadChildren() {
        let subs = fileSystemBackend.getSubdirectories(nodePath)
        loadedChildren = subs
        if (subs.length > 0)
            nodeHasChildren = true
    }

    function toggleExpand() {
        if (!expanded && loadedChildren.length === 0)
            loadChildren()
        expanded = !expanded
    }

    // ── Node row ──
    Rectangle {
        id: rowRect
        width: parent.width
        height: 22
        color: {
            if (fileSystemBackend.currentPath === treeNode.nodePath)
                return Win7Theme.navPanelItemSelected
            if (rowMa.containsMouse)
                return Win7Theme.navPanelItemHover
            return "transparent"
        }
        border.color: fileSystemBackend.currentPath === treeNode.nodePath
                      ? Win7Theme.navPanelItemSelectedBorder : "transparent"
        border.width: fileSystemBackend.currentPath === treeNode.nodePath ? 1 : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6 + treeNode.depth * 14
            spacing: 2

            Text {
                text: treeNode.expanded ? "▾" : "▸"
                Layout.preferredWidth: 12
                font.pixelSize: 8
                color: Win7Theme.navPanelExpandArrow
                opacity: (treeNode.nodeHasChildren || treeNode.loadedChildren.length > 0) ? 1.0 : 0.0
            }

            Image {
                width: 16; height: 16
                sourceSize: Qt.size(16, 16)
                source: treeNode.nodePath ? "image://fileicons/" + encodeURIComponent(treeNode.nodePath) : ""
                fillMode: Image.PreserveAspectFit
            }

            Text {
                Layout.fillWidth: true
                text: treeNode.nodeName
                font.family: Win7Theme.fontFamily
                font.pixelSize: Win7Theme.fontSizeNormal + 2
                color: Win7Theme.navPanelItemText
                elide: Text.ElideRight
            }
        }

        // Single MouseArea: clicking the arrow zone toggles expand, clicking elsewhere navigates
        MouseArea {
            id: rowMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: (mouse) => {
                let arrowLeft = 6 + treeNode.depth * 14
                let hasTree = treeNode.nodeHasChildren || treeNode.loadedChildren.length > 0
                if (hasTree && mouse.x >= arrowLeft && mouse.x <= arrowLeft + 16)
                    treeNode.toggleExpand()
                else
                    fileSystemBackend.navigateTo(treeNode.nodePath)
            }
        }
    }

    // ── Children ──
    Column {
        id: childCol
        y: rowRect.height
        width: parent.width
        visible: treeNode.expanded

        Repeater {
            model: treeNode.loadedChildren

            Loader {
                width: childCol.width
                height: status === Loader.Ready ? item.implicitHeight : 0
                source: Qt.resolvedUrl("FolderTreeNode.qml")
                onLoaded: {
                    item.nodePath = modelData.path
                    item.nodeName = modelData.name
                    item.depth = treeNode.depth + 1
                    item.nodeHasChildren = modelData.hasChildren
                }
            }
        }
    }

    // Auto-expand when the user navigates into a path under this node
    Connections {
        target: fileSystemBackend
        function onCurrentPathChanged() {
            let cur = fileSystemBackend.currentPath
            let isChild = treeNode.nodePath === "/" ? cur !== "/" : cur.startsWith(treeNode.nodePath + "/")
            if (isChild && !treeNode.expanded) {
                if (treeNode.loadedChildren.length === 0)
                    treeNode.loadChildren()
                treeNode.expanded = true
            }
        }
    }

    // Expand to the initial current path on creation
    Component.onCompleted: {
        let cur = fileSystemBackend.currentPath
        let isChild = nodePath === "/" ? cur !== "/" : cur.startsWith(nodePath + "/")
        if (isChild) {
            loadChildren()
            expanded = true
        }
    }
}
