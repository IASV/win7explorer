import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var pal
    property var model:       []
    property var selectedIds: ({})
    property string sortBy:  "name"
    property string sortDir: "asc"
    property var columnFilters: ({})

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)
    signal sortRequested(string col)
    signal filterChanged()

    spacing: 0

    readonly property var filteredModel: {
        var filters = root.columnFilters
        var hasAny = false
        for (var k in filters) { if (filters[k] && filters[k].length > 0) { hasAny = true; break } }
        if (!hasAny) return root.model
        var fm = []
        for (var i = 0; i < root.model.length; ++i) {
            var item = root.model[i]
            var ok = true
            for (var col in filters) {
                var arr = filters[col]
                if (!arr || arr.length === 0) continue
                var val
                if (col === "name")     val = item.name
                else if (col === "modified") val = item.modified
                else if (col === "type")     val = item.typeStr
                else if (col === "size")     val = item.size
                if (arr.indexOf(val) < 0) { ok = false; break }
            }
            if (ok) fm.push(item)
        }
        return fm
    }

    function uniqueValues(colId) {
        var seen = {}, arr = []
        for (var i = 0; i < root.model.length; ++i) {
            var it = root.model[i]
            var v = colId === "name" ? it.name : colId === "modified" ? it.modified
                  : colId === "type" ? it.typeStr : it.size
            if (v !== undefined && v !== null && v !== "" && !seen[v]) { seen[v] = true; arr.push(v) }
        }
        return arr.sort()
    }

    function toggleFilter(colId, value) {
        var copy = JSON.parse(JSON.stringify(root.columnFilters))
        var arr = copy[colId] ? copy[colId].slice() : []
        var idx = arr.indexOf(value)
        if (idx >= 0) arr.splice(idx, 1); else arr.push(value)
        copy[colId] = arr
        root.columnFilters = copy
        root.filterChanged()
    }

    function clearFilter(colId) {
        var copy = JSON.parse(JSON.stringify(root.columnFilters))
        delete copy[colId]
        root.columnFilters = copy
        root.filterChanged()
    }

    function isFiltered(colId) {
        return root.columnFilters[colId] && root.columnFilters[colId].length > 0
    }

    // Column header
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        gradient: Gradient {
            GradientStop { position: 0; color: root.pal.tbar1 }
            GradientStop { position: 1; color: root.pal.tbar2 }
        }
        border.color: root.pal.borderSoft

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: [
                    { id: "name",     label: "Nombre",                stretch: 3 },
                    { id: "modified", label: "Fecha de modificación", stretch: 2 },
                    { id: "type",     label: "Tipo",                  stretch: 1 },
                    { id: "size",     label: "Tamaño",                stretch: 1 }
                ]
                delegate: Rectangle {
                    id: headerCell
                    readonly property string colId:     modelData.id
                    readonly property int    colStretch: modelData.stretch

                    Layout.fillWidth: true
                    Layout.preferredWidth: modelData.stretch * 100
                    Layout.fillHeight: true
                    color: colHov.containsMouse ? root.pal.accentSoft : "transparent"
                    border.color: root.pal.borderSoft

                    // colHov declared FIRST — lower z so RowLayout items intercept clicks
                    MouseArea {
                        id: colHov
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.sortRequested(headerCell.colId)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 2

                        Label {
                            text: modelData.label + (root.isFiltered(headerCell.colId) ? " ●" : "")
                            color: root.sortBy === headerCell.colId ? root.pal.accent : root.pal.text
                            font.pixelSize: 11; font.bold: true
                            Layout.fillWidth: true
                        }

                        // Filter dropdown arrow (visible on hover or when filter active)
                        Rectangle {
                            visible: colHov.containsMouse || root.isFiltered(headerCell.colId)
                            width: 16; height: parent.height
                            color: arrowHov.containsMouse ? root.pal.accentSoft : "transparent"
                            Label {
                                anchors.centerIn: parent
                                text: "▾"; color: root.pal.muted; font.pixelSize: 9
                            }
                            MouseArea {
                                id: arrowHov
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    filterMenu.popup()
                                }
                            }

                            Menu {
                                id: filterMenu
                                palette.window:          root.pal.panel
                                palette.windowText:      root.pal.text
                                palette.base:            root.pal.content
                                palette.highlight:       root.pal.accentSoft
                                palette.highlightedText: root.pal.accent

                                MenuItem {
                                    text: "Seleccionar todo"
                                    onTriggered: root.clearFilter(headerCell.colId)
                                }
                                MenuSeparator {}
                                Repeater {
                                    model: root.uniqueValues(headerCell.colId)
                                    MenuItem {
                                        text: modelData
                                        checkable: true
                                        checked: {
                                            var f = root.columnFilters[headerCell.colId]
                                            return !f || f.length === 0 || f.indexOf(modelData) >= 0
                                        }
                                        onTriggered: root.toggleFilter(headerCell.colId, modelData)
                                    }
                                }
                            }
                        }

                        Label {
                            visible: root.sortBy === headerCell.colId
                            text: root.sortDir === "asc" ? "▲" : "▼"
                            color: root.pal.accent; font.pixelSize: 9
                        }
                    }
                }
            }
        }
    }

    // File rows
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.filteredModel

        delegate: Rectangle {
            width:  ListView.view.width
            height: 24
            color:  root.selectedIds[modelData.id] ? root.pal.selection
                  : detArea.containsMouse          ? root.pal.accentSoft : "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 300
                    Layout.leftMargin: 8; spacing: 6
                    Image {
                        source: modelData.iconSrc || ""
                        Layout.preferredWidth: 16; Layout.preferredHeight: 16
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        text: modelData.name
                        color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                        font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                    }
                }
                Label { Layout.fillWidth: true; Layout.preferredWidth: 200; Layout.leftMargin: 8
                    text: modelData.modified || "—"
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11 }
                Label { Layout.fillWidth: true; Layout.preferredWidth: 100; Layout.leftMargin: 8
                    text: modelData.typeStr || "—"
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11 }
                Label { Layout.fillWidth: true; Layout.preferredWidth: 100
                    Layout.leftMargin: 8; Layout.rightMargin: 8
                    text: modelData.size || (modelData.type === "folder" ? "" : "—")
                    color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                    font.pixelSize: 11 }
            }

            MouseArea {
                id: detArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    root.itemClicked(modelData,
                        !!(mouse.modifiers & Qt.ControlModifier),
                        !!(mouse.modifiers & Qt.ShiftModifier))
                    if (mouse.button === Qt.RightButton)
                        root.contextMenuRequested(modelData)
                }
                onDoubleClicked: root.itemDoubleClicked(modelData)
            }
        }
    }
}
