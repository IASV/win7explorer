import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

// ═══════════════════════════════════════════════════
// Preview Panel: Right-side panel showing file content
// Toggled by the CommandBar preview button
// ═══════════════════════════════════════════════════
Rectangle {
    id: previewPanel

    color: Win7Theme.contentBg

    // Left border
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Win7Theme.navPanelBorder
    }

    property var info: fileSystemBackend.selectedFileInfo

    readonly property bool isImage: {
        if (!info || !info.path) return false
        let ext = info.path.split('.').pop().toLowerCase()
        return ["jpg","jpeg","png","gif","bmp","webp","svg"].indexOf(ext) >= 0
    }
    readonly property bool isText: {
        if (!info || !info.path || info.isDir) return false
        let ext = info.path.split('.').pop().toLowerCase()
        return ["txt","md","markdown","sh","bash","py","js","ts","cpp","c","h",
                "hpp","rs","go","java","html","css","xml","json","yaml","yml",
                "toml","ini","cfg","conf","log","csv","sql"].indexOf(ext) >= 0
    }

    // ── Nothing selected ──
    Text {
        anchors.centerIn: parent
        text: "Sin selección"
        font.family: Win7Theme.fontFamily
        font.pixelSize: Win7Theme.fontSizeNormal + 1
        color: Win7Theme.itemTextSecondary
        visible: !info || !info.name
    }

    // ── Image preview ──
    ScrollView {
        anchors.fill: parent
        anchors.margins: 8
        visible: previewPanel.isImage && info && info.name
        clip: true

        Image {
            source: (previewPanel.isImage && info && info.path) ? "file://" + info.path : ""
            fillMode: Image.PreserveAspectFit
            width: previewPanel.width - 16
            height: previewPanel.height - 16
            asynchronous: true

            // Loading indicator
            BusyIndicator {
                anchors.centerIn: parent
                running: parent.status === Image.Loading
            }
        }
    }

    // ── Text preview ──
    ScrollView {
        anchors.fill: parent
        anchors.margins: 6
        visible: previewPanel.isText && info && info.name && !previewPanel.isImage
        clip: true

        TextArea {
            id: textPreview
            readOnly: true
            wrapMode: TextArea.Wrap
            font.family: "monospace"
            font.pixelSize: Win7Theme.fontSizeNormal + 1
            color: Win7Theme.itemText
            background: null
            text: {
                if (!previewPanel.isText || !info || !info.path) return ""
                return fileSystemBackend.readFilePreview(info.path, 4000) || "[Archivo vacío o no legible]"
            }
        }
    }

    // ── Non-previewable ──
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: info && info.name && !previewPanel.isImage && !previewPanel.isText

        Image {
            Layout.alignment: Qt.AlignHCenter
            width: 64; height: 64
            sourceSize: Qt.size(64, 64)
            source: (info && info.path) ? "image://fileicons/" + encodeURIComponent(info.path) : ""
            fillMode: Image.PreserveAspectFit
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Vista previa no disponible"
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeNormal + 1
            color: Win7Theme.itemTextSecondary
        }
    }
}
