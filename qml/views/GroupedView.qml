import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root
    property var pal
    property var model:       []
    property var selectedIds: ({})

    signal itemClicked(var item, bool ctrl, bool shift)
    signal itemDoubleClicked(var item)
    signal contextMenuRequested(var item)

    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    Column {
        width: root.availableWidth
        spacing: 0
        topPadding: 6
        bottomPadding: 16

        Repeater {
            model: [
                { title: "Unidades de disco duro",
                  filter: function(i){ return i.type === "drive" && i.kind !== "disc" && i.kind !== "removable" && i.kind !== "mtp" } },
                { title: "Dispositivos con almacenamiento extraíble",
                  filter: function(i){ return i.type === "drive" && (i.kind === "disc" || i.kind === "removable" || i.kind === "mtp") } },
                { title: "Ubicaciones de red",
                  filter: function(i){ return i.kind === "pc" || i.kind === "printer" || i.type === "network" } },
                { title: "Carpetas",
                  filter: function(i){ return i.type === "folder" && i.kind !== "pc" && i.kind !== "printer" } }
            ]

            delegate: Column {
                id: sectionCol
                width: root.availableWidth
                spacing: 0

                property var  subset:   root.model ? root.model.filter(modelData.filter) : []
                property bool expanded: true
                visible: subset.length > 0

                // ── Section header ─────────────────────────────────────────
                Item {
                    width: parent.width
                    height: 26

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sectionCol.expanded = !sectionCol.expanded
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 14
                        anchors.topMargin: 2
                        spacing: 5

                        // Collapse triangle — points down when expanded, right when collapsed
                        Canvas {
                            Layout.preferredWidth:  9
                            Layout.preferredHeight: 9
                            Layout.alignment: Qt.AlignVCenter
                            rotation: sectionCol.expanded ? 0 : -90
                            Behavior on rotation { NumberAnimation { duration: 140 } }
                            property color fg: root.pal.accent
                            onFgChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, 9, 9)
                                ctx.fillStyle = fg
                                ctx.beginPath()
                                ctx.moveTo(0.5, 1.5); ctx.lineTo(8.5, 1.5); ctx.lineTo(4.5, 7.5)
                                ctx.closePath(); ctx.fill()
                            }
                        }

                        // Title + count
                        Label {
                            text: modelData.title + " (" + sectionCol.subset.length + ")"
                            color: root.pal.accent
                            font.pixelSize: 12
                            font.bold: true
                        }

                        // Separator line
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            height: 1
                            color: root.pal.border
                        }
                    }
                }

                // ── Drive / item cards ─────────────────────────────────────
                Flow {
                    visible: sectionCol.expanded
                    clip: true
                    width: parent.width
                    leftPadding:   12
                    rightPadding:  12
                    topPadding:    4
                    bottomPadding: 14
                    spacing: 4

                    Behavior on height { NumberAnimation { duration: 140 } }

                    Repeater {
                        model: sectionCol.subset

                        delegate: Rectangle {
                            width:  190
                            height: 86
                            radius: 2
                            color:  root.selectedIds[modelData.id] ? root.pal.selection
                                  : cardArea.containsMouse          ? root.pal.accentSoft
                                  :                                   "transparent"
                            border.color: root.selectedIds[modelData.id] ? root.pal.selectionBorder
                                        : cardArea.containsMouse          ? root.pal.border
                                        :                                   "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                // Drive / folder icon
                                Image {
                                    source: modelData.iconSrc || ""
                                    Layout.preferredWidth:  52
                                    Layout.preferredHeight: 52
                                    Layout.alignment: Qt.AlignVCenter
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width:  52
                                    sourceSize.height: 52
                                }

                                // Name + usage bar + free text
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    Item { Layout.fillHeight: true }

                                    Label {
                                        text: modelData.name
                                        color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.text
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Disk usage bar — Win7 Aero style
                                    Item {
                                        id: barItem
                                        visible: modelData.total !== undefined && modelData.total > 0
                                        Layout.fillWidth: true
                                        height: 14

                                        readonly property real usedRatio: modelData.total > 0
                                            ? Math.min((modelData.total - modelData.free) / modelData.total, 1.0)
                                            : 0
                                        readonly property bool critical: usedRatio > 0.9

                                        // Container — inset look (1px border, gray background)
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "#dce0e4"
                                            border.color: "#9aa0a8"
                                            border.width: 1

                                            // Filled portion
                                            Rectangle {
                                                x: 1; y: 1
                                                width:  (parent.width  - 2) * barItem.usedRatio
                                                height: parent.height - 2
                                                clip: true

                                                // Bottom half — base color
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: barItem.critical ? "#cc1a1a" : "#0090c8"
                                                }
                                                // Top half — lighter gloss band
                                                Rectangle {
                                                    anchors.top: parent.top
                                                    width: parent.width
                                                    height: Math.ceil(parent.height * 0.50)
                                                    color: barItem.critical ? "#e85858" : "#7ad8f4"
                                                }
                                                // Subtle shine line at very top
                                                Rectangle {
                                                    anchors.top: parent.top
                                                    width: parent.width
                                                    height: 1
                                                    color: barItem.critical ? "#f08080" : "#b8eeff"
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        visible: modelData.total !== undefined && modelData.total > 0
                                        text: modelData.free.toFixed(1) + " GB libres de " + modelData.total.toFixed(1) + " GB"
                                        color: root.selectedIds[modelData.id] ? root.pal.selText : root.pal.muted
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Item { Layout.fillHeight: true }
                                }
                            }

                            MouseArea {
                                id: cardArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    root.itemClicked(modelData, false, false)
                                    if (mouse.button === Qt.RightButton)
                                        root.contextMenuRequested(modelData)
                                }
                                onDoubleClicked: root.itemDoubleClicked(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
