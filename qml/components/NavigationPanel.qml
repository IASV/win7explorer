import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    id: root
    property var    pal
    property string currentPath: ""
    property var    favorites: []

    signal folderActivated(string path)

    color: pal.sidebar
    border.color: pal.borderSoft

    // Defer building the (heavy) tree until after the window's first paint.
    // The panel is visible immediately with its sidebar colour; the tree
    // streams in asynchronously, so the rest of the UI doesn't block on it.
    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: treeComp
    }

    Component {
        id: treeComp
        FolderTree {
            pal:         root.pal
            currentPath: root.currentPath
            favorites:   root.favorites
            onFolderActivated: function(path) { root.folderActivated(path) }
        }
    }
}
