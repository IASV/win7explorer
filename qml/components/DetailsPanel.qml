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
    property int    panelHeight:       80

    property var    fileMetadata:      ({})
    property bool   metaModified:      false
    property string currentFolderIconSrc: "image://fileicons/folder-closed"

    readonly property bool   computerMode: useGroupedView && currentKind === "computer" && selectedCount === 0
    readonly property string metaCategory: fileMetadata.category || ""

    // ── Metadata loading ───────────────────────────────────────────────────
    onDetailItemChanged: {
        root.fileMetadata = {}
        root.metaModified = false
        albumField.loadedValue = ""; albumField.text = ""
        genreField.loadedValue = ""; genreField.text = ""
        metaTimer.restart()
    }

    Timer {
        id: metaTimer
        interval: 150
        onTriggered: {
            if (root.detailItem && root.detailItem.id && root.detailItem.id.startsWith('/')) {
                var meta = fsBackend.getFileMetadata(root.detailItem.id)
                root.fileMetadata = meta
                albumField.loadedValue = meta.album || ""
                albumField.text = albumField.loadedValue
                genreField.loadedValue = meta.genre || ""
                genreField.text = genreField.loadedValue
            } else {
                root.fileMetadata = {}
            }
            root.metaModified = false
        }
    }

    // ── Right-click size menu ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                var h = nativeMenu.showDetailsPanelSizeMenu()
                if (h > 0) root.panelHeight = h
            }
        }
    }

    color: pal.panel
    border.color: pal.borderSoft

    // ══ 1. COMPUTER MODE ══════════════════════════════════════════════════
    RowLayout {
        visible: root.computerMode
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 8;   anchors.bottomMargin: 8
        spacing: 14

        Image {
            source: "image://fileicons/computer"
            sourceSize: Qt.size(52, 52)
            Layout.preferredWidth: 52; Layout.preferredHeight: 52
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout { spacing: 3
            Label { text: root.systemInfo ? root.systemInfo.hostname : ""
                    color: pal.text; font.pixelSize: 13; font.bold: true }
            Label { text: root.systemInfo ? root.systemInfo.osVersion : ""
                    color: pal.muted; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: pal.border; opacity: 0.5 }
        ColumnLayout { Layout.fillWidth: true; spacing: 3
            Label { text: root.systemInfo ? ("Memoria: " + root.systemInfo.ramFormatted) : ""
                    color: pal.text; font.pixelSize: 11 }
            Label { text: root.systemInfo ? ("Procesador: " + root.systemInfo.cpuModel) : ""
                    color: pal.muted; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }

    // ══ 2. NO SELECTION ════════════════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && !root.detailItem && root.selectedCount === 0
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 8;   anchors.bottomMargin: 8
        spacing: 14

        Image {
            source: root.currentFolderIconSrc
            sourceSize: Qt.size(44, 44)
            Layout.preferredWidth: 44; Layout.preferredHeight: 44
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 3
            Label { text: root.currentFolderName; color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true }
            Label { text: root.currentItemCount + " elemento" + (root.currentItemCount === 1 ? "" : "s")
                    color: pal.muted; font.pixelSize: 11 }
        }
    }

    // ══ 3. MULTI-SELECTION ═════════════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && root.selectedCount > 1
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 8;   anchors.bottomMargin: 8
        spacing: 14

        Canvas {
            width: 44; height: 44
            property color fg: root.pal.muted
            onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
            onPaint: {
                var ctx = getContext("2d"); ctx.clearRect(0, 0, 44, 44)
                ctx.strokeStyle = fg; ctx.globalAlpha = 0.22; ctx.lineWidth = 1.2
                ctx.strokeRect(4,  12, 26, 30)
                ctx.strokeRect(8,  8,  26, 30)
                ctx.strokeRect(12, 4,  26, 30)
                ctx.beginPath()
                ctx.moveTo(16, 16); ctx.lineTo(34, 16)
                ctx.moveTo(16, 21); ctx.lineTo(34, 21)
                ctx.stroke()
            }
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 3
            Label { text: root.selectedCount + " elementos seleccionados"
                    color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true }
            Label { visible: root.totalSelectedSize !== ""
                    text: "Tamaño: " + root.totalSelectedSize
                    color: pal.muted; font.pixelSize: 11 }
        }
    }

    // ══ 4. DRIVE ═══════════════════════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && !!root.detailItem && root.detailItem.type === "drive"
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 8;   anchors.bottomMargin: 8
        spacing: 14

        Image {
            source: root.detailItem ? (root.detailItem.iconSrc || "") : ""
            sourceSize: Qt.size(48, 48)
            Layout.preferredWidth: 48; Layout.preferredHeight: 48
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 4
            Label { text: root.detailItem ? root.detailItem.name : ""
                    color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true }
            RowLayout { spacing: 20
                Label { text: "Espacio disponible: " + (root.detailItem ? (root.detailItem.free || 0).toFixed(1) : "0") + " GB"
                        color: pal.muted; font.pixelSize: 11 }
                Label { text: "Total: " + (root.detailItem ? (root.detailItem.total || 0).toFixed(1) : "0") + " GB"
                        color: pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.typeStr
                        text: "Sistema de archivos: " + (root.detailItem ? root.detailItem.typeStr : "")
                        color: pal.muted; font.pixelSize: 11 }
            }
        }
    }

    // ══ 5. AUDIO ═══════════════════════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && !!root.detailItem && root.metaCategory === "audio"
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 6;   anchors.bottomMargin: 6
        spacing: 14

        Image {
            source: root.detailItem ? (root.detailItem.iconSrc || "") : ""
            sourceSize: Qt.size(52, 52)
            Layout.preferredWidth: 52; Layout.preferredHeight: 52
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            clip: true

            // Row 1: title + artist + duration
            RowLayout { spacing: 14; Layout.fillWidth: true
                Label {
                    text: (root.fileMetadata.title || "") !== "" ? root.fileMetadata.title
                          : (root.detailItem ? root.detailItem.name : "")
                    color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Label {
                    visible: (root.fileMetadata.artist || "") !== ""
                    text: "Intérpretes: " + (root.fileMetadata.artist || "")
                    color: pal.text; font.pixelSize: 11
                    elide: Text.ElideRight; Layout.maximumWidth: 200
                }
                Label {
                    visible: (root.fileMetadata.duration || "") !== ""
                    text: "Duración: " + (root.fileMetadata.duration || "")
                    color: pal.muted; font.pixelSize: 11
                }
            }

            // Row 2: type + editable album  (medium+)
            RowLayout {
                visible: root.panelHeight >= 70
                spacing: 10; Layout.fillWidth: true

                Label { text: root.detailItem ? (root.detailItem.typeStr || "") : ""
                        color: pal.muted; font.pixelSize: 11 }

                Label { text: "Álbum:"; color: pal.muted; font.pixelSize: 11 }
                TextField {
                    id: albumField
                    property string loadedValue: ""
                    implicitWidth: 140; height: 20
                    font.pixelSize: 11; color: pal.text
                    leftPadding: 4; rightPadding: 4; topPadding: 1; bottomPadding: 1
                    background: Rectangle {
                        border.color: albumField.activeFocus ? pal.accent : pal.borderSoft
                        color: pal.content; radius: 2
                    }
                    onTextChanged: if (text !== loadedValue) root.metaModified = true
                }

                Item { Layout.fillWidth: true }
            }

            // Row 3: editable genre + save/cancel  (large only)
            RowLayout {
                visible: root.panelHeight >= 95
                spacing: 10; Layout.fillWidth: true

                Label { text: "Género:"; color: pal.muted; font.pixelSize: 11 }
                TextField {
                    id: genreField
                    property string loadedValue: ""
                    implicitWidth: 140; height: 20
                    font.pixelSize: 11; color: pal.text
                    leftPadding: 4; rightPadding: 4; topPadding: 1; bottomPadding: 1
                    background: Rectangle {
                        border.color: genreField.activeFocus ? pal.accent : pal.borderSoft
                        color: pal.content; radius: 2
                    }
                    onTextChanged: if (text !== loadedValue) root.metaModified = true
                }

                // Save / Cancel
                RowLayout {
                    visible: root.metaModified
                    spacing: 6
                    Repeater {
                        model: [
                            { label: "Guardar",   isSave: true  },
                            { label: "Cancelar",  isSave: false }
                        ]
                        delegate: Rectangle {
                            implicitWidth: btnLbl.implicitWidth + 18; height: 22
                            color: btnMa.containsMouse ? pal.accentSoft : pal.panel
                            border.color: pal.border; radius: 3
                            Label { id: btnLbl; anchors.centerIn: parent; text: modelData.label
                                    font.pixelSize: 11; color: pal.text }
                            MouseArea {
                                id: btnMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (modelData.isSave) {
                                        fsBackend.saveFileMetadata(root.detailItem.id, {
                                            album: albumField.text,
                                            genre: genreField.text
                                        })
                                        albumField.loadedValue = albumField.text
                                        genreField.loadedValue = genreField.text
                                    } else {
                                        albumField.text = albumField.loadedValue
                                        genreField.text = genreField.loadedValue
                                    }
                                    root.metaModified = false
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // ══ 6. IMAGE ═══════════════════════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && !!root.detailItem && root.metaCategory === "image"
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 6;   anchors.bottomMargin: 6
        spacing: 14

        Image {
            source: root.detailItem ? (root.detailItem.previewSrc || root.detailItem.iconSrc || "") : ""
            sourceSize: Qt.size(52, 52)
            Layout.preferredWidth: 52; Layout.preferredHeight: 52
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout { Layout.fillWidth: true; spacing: 3; clip: true
            Label { text: root.detailItem ? root.detailItem.name : ""
                    color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true }

            RowLayout { spacing: 18
                Label { text: root.detailItem ? (root.detailItem.typeStr || "") : ""; color: pal.muted; font.pixelSize: 11 }
                Label { visible: (root.fileMetadata.dimensions || "") !== ""
                        text: root.fileMetadata.dimensions || ""; color: pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.size
                        text: root.detailItem ? (root.detailItem.size || "") : ""; color: pal.muted; font.pixelSize: 11 }
            }

            RowLayout { visible: root.panelHeight >= 70; spacing: 16
                Label { text: "Etiquetas:"; color: pal.muted; font.pixelSize: 11 }
                Label { text: "Agregar una etiqueta"; color: pal.accent; font.pixelSize: 11; opacity: 0.85 }
                Item { Layout.fillWidth: true }
            }
        }
    }

    // ══ 7. VIDEO ═══════════════════════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && !!root.detailItem && root.metaCategory === "video"
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 8;   anchors.bottomMargin: 8
        spacing: 14

        Image {
            source: root.detailItem ? (root.detailItem.iconSrc || "") : ""
            sourceSize: Qt.size(48, 48)
            Layout.preferredWidth: 48; Layout.preferredHeight: 48
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 4
            Label { text: root.detailItem ? root.detailItem.name : ""
                    color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true }
            RowLayout { spacing: 18
                Label { text: root.detailItem ? (root.detailItem.typeStr || "") : ""; color: pal.muted; font.pixelSize: 11 }
                Label { visible: (root.fileMetadata.dimensions || "") !== ""
                        text: root.fileMetadata.dimensions || ""; color: pal.muted; font.pixelSize: 11 }
                Label { visible: (root.fileMetadata.duration || "") !== ""
                        text: "Duración: " + (root.fileMetadata.duration || ""); color: pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.size
                        text: root.detailItem ? (root.detailItem.size || "") : ""; color: pal.muted; font.pixelSize: 11 }
            }
        }
    }

    // ══ 8. GENERIC FILE / FOLDER ═══════════════════════════════════════════
    RowLayout {
        visible: !root.computerMode && !!root.detailItem
                 && root.detailItem.type !== "drive"
                 && root.metaCategory !== "audio"
                 && root.metaCategory !== "image"
                 && root.metaCategory !== "video"
        anchors.fill: parent
        anchors.leftMargin: 14; anchors.rightMargin: 14
        anchors.topMargin: 6;   anchors.bottomMargin: 6
        spacing: 14

        Image {
            source: root.detailItem ? (root.detailItem.iconSrc || "") : ""
            sourceSize: Qt.size(48, 48)
            Layout.preferredWidth: 48; Layout.preferredHeight: 48
            fillMode: Image.PreserveAspectFit
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 3; clip: true
            Label { text: root.detailItem ? root.detailItem.name : ""
                    color: pal.text; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true }
            RowLayout { spacing: 18
                Label { text: root.detailItem ? (root.detailItem.typeStr || "") : ""; color: pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.size
                        text: root.detailItem ? (root.detailItem.size || "") : ""; color: pal.muted; font.pixelSize: 11 }
                Label { visible: root.detailItem && !!root.detailItem.modified
                        text: root.detailItem ? ("Modificado: " + (root.detailItem.modified || "")) : ""
                        color: pal.muted; font.pixelSize: 11 }
            }
        }
    }
}
