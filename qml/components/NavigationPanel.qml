import QtQuick
import QtQuick.Controls
import Win7Explorer

Rectangle {
    id: root
    property var    pal
    property string currentPath: ""
    property var    favorites: []

    signal folderActivated(string path)

    color: pal.sidebar
    border.color: pal.borderSoft

    FolderTree {
        anchors.fill: parent
        pal:         root.pal
        currentPath: root.currentPath
        favorites:   root.favorites
        onFolderActivated: function(path) { root.folderActivated(path) }
    }
}
