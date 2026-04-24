import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

// ═══════════════════════════════════════════════════
// Details Panel: Shows info about selected file(s)
// Located at the bottom of the content area
// ═══════════════════════════════════════════════════
Rectangle {
    id: detailsPanel

    gradient: Gradient {
        GradientStop { position: 0.0; color: Win7Theme.detailsPanelGradientTop }
        GradientStop { position: 1.0; color: Win7Theme.detailsPanelGradientBottom }
    }

    property var info: fileSystemBackend.selectedFileInfo

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 12

        // ── File Icon / Thumbnail ──
        Item {
            width: 50
            height: 50
            visible: info && info.name
            Layout.alignment: Qt.AlignVCenter

            // Image thumbnail for supported image types
            Image {
                id: thumbImage
                anchors.fill: parent
                source: (info && info.path && detailsPanel.isImageFile(info.path))
                        ? "file://" + info.path : ""
                fillMode: Image.PreserveAspectFit
                clip: true
                asynchronous: true
                visible: status === Image.Ready
            }

            // Fallback: system theme icon (for non-image or while image loads)
            Image {
                anchors.fill: parent
                sourceSize: Qt.size(48, 48)
                source: (info && info.path) ? "image://fileicons/" + encodeURIComponent(info.path) : ""
                fillMode: Image.PreserveAspectFit
                visible: !thumbImage.visible && (info && !!info.path)
            }
        }

        // ── File Details ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1
            visible: info && info.name

            // File name (bold, larger)
            Text {
                text: info ? (info.name || "") : ""
                font.family: Win7Theme.fontFamily
                font.pixelSize: Win7Theme.fontSizeMedium
                font.bold: true
                color: Win7Theme.detailsPanelText
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            // Type
            Text {
                text: info ? (info.type || "") : ""
                font.family: Win7Theme.fontFamily
                font.pixelSize: Win7Theme.fontSizeNormal + 1
                color: Win7Theme.detailsPanelLabel
            }
        }

        // ── Right side: Date & Size ──
        ColumnLayout {
            spacing: 1
            visible: info && info.name
            Layout.alignment: Qt.AlignTop

            DetailRow {
                label: "Fecha de modificación:"
                value: info ? (info.modified || "") : ""
            }

            DetailRow {
                label: "Tamaño:"
                value: info ? (info.sizeFormatted || "") : ""
                visible: info && !info.isDir
            }

            DetailRow {
                label: "Fecha de creación:"
                value: info ? (info.created || "") : ""
            }
        }
    }

    // ── Empty state: show item count ──
    Text {
        anchors.centerIn: parent
        text: fileSystemBackend.itemCount + " elementos"
        font.family: Win7Theme.fontFamily
        font.pixelSize: Win7Theme.fontSizeNormal + 1
        color: Win7Theme.detailsPanelLabel
        visible: !info || !info.name
    }

    function isImageFile(path) {
        if (!path) return false
        let ext = path.split('.').pop().toLowerCase()
        return ["jpg","jpeg","png","gif","bmp","webp"].indexOf(ext) >= 0
    }

    function fileEmoji(filename) {
        let ext = filename.split('.').pop().toLowerCase()
        switch (ext) {
            case "jpg": case "jpeg": case "png": case "gif": case "bmp": case "webp": return "🖼"
            case "mp3": case "wav": case "flac": case "ogg": case "aac": return "🎵"
            case "mp4": case "avi": case "mkv": case "mov": case "webm": return "🎬"
            case "pdf": return "📕"
            case "doc": case "docx": case "odt": return "📝"
            case "xls": case "xlsx": case "ods": return "📊"
            case "zip": case "tar": case "gz": case "7z": case "rar": return "📦"
            case "py": case "js": case "cpp": case "c": case "h": case "rs": case "go": case "sh": return "📜"
            case "html": case "css": case "xml": case "json": return "🌐"
            default: return "📄"
        }
    }

    // ═══ Detail Row Component ═══
    component DetailRow: RowLayout {
        property string label: ""
        property string value: ""
        spacing: 6

        Text {
            text: label
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeSmall + 2
            color: Win7Theme.detailsPanelLabel
        }
        Text {
            text: value
            font.family: Win7Theme.fontFamily
            font.pixelSize: Win7Theme.fontSizeSmall + 2
            color: Win7Theme.detailsPanelText
        }
    }
}
