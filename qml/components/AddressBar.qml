import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var    pal
    property bool   canGoBack:    false
    property bool   canGoForward: false
    property bool   canGoUp:      false
    property var    pathToCurrent: []

    signal backRequested
    signal forwardRequested
    signal upRequested
    signal segmentClicked(string pathOrId)
    property string currentFolderName: ""
    signal searchChanged(string text)

    border.color: pal.borderSoft
    gradient: Gradient {
        GradientStop { position: 0; color: pal.tbar1 }
        GradientStop { position: 1; color: pal.tbar2 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8; anchors.rightMargin: 10
        anchors.topMargin: 6;  anchors.bottomMargin: 6
        spacing: 2

        // ── Back button ──────────────────────────────────────────────────
        Item {
            Layout.preferredWidth: 29; Layout.preferredHeight: 27

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: {
                    if (!root.canGoBack)   return "qrc:/icons/nav-back-disabled.png"
                    if (backMa.pressed)    return "qrc:/icons/nav-back-pressed.png"
                    if (backMa.containsMouse) return "qrc:/icons/nav-back-hover.png"
                    return "qrc:/icons/nav-back-normal.png"
                }
            }
            MouseArea {
                id: backMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.canGoBack
                cursorShape: root.canGoBack ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.backRequested()
            }
        }

        // ── Forward button ───────────────────────────────────────────────
        Item {
            Layout.preferredWidth: 29; Layout.preferredHeight: 27

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: {
                    if (!root.canGoForward)      return "qrc:/icons/nav-forward-disabled.png"
                    if (fwdMa.pressed)           return "qrc:/icons/nav-forward-pressed.png"
                    if (fwdMa.containsMouse)     return "qrc:/icons/nav-forward-hover.png"
                    return "qrc:/icons/nav-forward-normal.png"
                }
            }
            MouseArea {
                id: fwdMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.canGoForward
                cursorShape: root.canGoForward ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.forwardRequested()
            }
        }

        // ── Down chevron (navigate up) ──────────────────────────────────
        Item {
            Layout.preferredWidth: 16; Layout.preferredHeight: 27
            opacity: root.canGoUp ? 1.0 : 0.35
            Canvas {
                anchors.centerIn: parent; width: 9; height: 6
                property color fg: root.pal.text
                onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, 9, 6)
                    ctx.fillStyle = fg
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(9, 0); ctx.lineTo(4.5, 6)
                    ctx.closePath(); ctx.fill()
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.canGoUp
                cursorShape: root.canGoUp ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.upRequested()
            }
        }

        // ── Breadcrumb bar ───────────────────────────────────────────────
        Rectangle {
            id: breadcrumbBar
            Layout.fillWidth: true; Layout.preferredHeight: 26
            color: root.pal.content; border.color: root.pal.borderSoft; radius: 3; clip: true

            property bool textEditMode: false

            // Click on bar background → enter text mode
            MouseArea {
                anchors.fill: parent
                onDoubleClicked: {
                    breadcrumbBar.textEditMode = true
                    var last = root.pathToCurrent
                    pathField.text = last.length > 0 ? (last[last.length-1].path || last[last.length-1].id || "") : ""
                    pathField.selectAll()
                    pathField.forceActiveFocus()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4; anchors.rightMargin: 4
                spacing: 0

                // Folder icon (I2: click → text mode)
                Image {
                    source: "qrc:/icons/folder-closed.png"
                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            breadcrumbBar.textEditMode = !breadcrumbBar.textEditMode
                            if (breadcrumbBar.textEditMode) {
                                var last = root.pathToCurrent
                                pathField.text = last.length > 0 ? (last[last.length-1].path || last[last.length-1].id || "") : ""
                                pathField.selectAll()
                                pathField.forceActiveFocus()
                            }
                        }
                    }
                }

                // Text edit mode (I2)
                TextField {
                    id: pathField
                    visible: breadcrumbBar.textEditMode
                    Layout.fillWidth: true; Layout.preferredHeight: 22
                    background: Item {}
                    color: root.pal.text; font.pixelSize: 12; leftPadding: 6
                    selectByMouse: true
                    Keys.onReturnPressed: { root.segmentClicked(text); breadcrumbBar.textEditMode = false }
                    Keys.onEscapePressed: breadcrumbBar.textEditMode = false
                }

                // Breadcrumb segments (I1: with dropdown ►)
                Repeater {
                    model: breadcrumbBar.textEditMode ? [] : root.pathToCurrent
                    delegate: RowLayout {
                        id: segRow
                        spacing: 0
                        property var siblings: []

                        // Separator chevron
                        Canvas {
                            visible: index > 0
                            Layout.preferredWidth: 8; Layout.preferredHeight: 10
                            property color fg: root.pal.muted
                            onFgChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, 8, 10); ctx.strokeStyle = fg
                                ctx.lineWidth = 1.4; ctx.lineCap = "round"
                                ctx.beginPath(); ctx.moveTo(2,1); ctx.lineTo(6,5); ctx.lineTo(2,9); ctx.stroke()
                            }
                        }

                        Rectangle {
                            id: crumbRect
                            Layout.preferredHeight: 20
                            color: (crumbMa.containsMouse || arrowMa.containsMouse) ? root.pal.accentSoft : "transparent"
                            radius: 2
                            implicitWidth: crumbLbl.implicitWidth + (arrowBox.visible ? 20 : 10)

                            Label {
                                id: crumbLbl
                                anchors.left: parent.left; anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: (crumbMa.containsMouse || arrowMa.containsMouse) ? root.pal.accent : root.pal.text
                                font.pixelSize: 12
                            }

                            // Dropdown arrow ► (I1)
                            Rectangle {
                                id: arrowBox
                                visible: crumbMa.containsMouse || arrowMa.containsMouse
                                anchors.right: parent.right; anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12; height: 18
                                color: arrowMa.containsMouse ? root.pal.accentSoft : "transparent"
                                radius: 2
                                Canvas {
                                    anchors.centerIn: parent; width: 6; height: 8
                                    property color fg: root.pal.muted
                                    onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0,0,6,8)
                                        ctx.fillStyle = fg
                                        ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(5,4); ctx.lineTo(0,8)
                                        ctx.closePath(); ctx.fill()
                                    }
                                }
                            }

                            // Label click → navigate
                            MouseArea {
                                id: crumbMa
                                anchors.left: parent.left; anchors.right: arrowBox.left
                                anchors.top: parent.top; anchors.bottom: parent.bottom
                                hoverEnabled: true
                                onClicked: root.segmentClicked(modelData.path || modelData.id)
                            }

                            // Arrow click → show siblings
                            MouseArea {
                                id: arrowMa
                                anchors.left: arrowBox.left; anchors.right: parent.right
                                anchors.top: parent.top; anchors.bottom: parent.bottom
                                hoverEnabled: true
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    var p = modelData.path || ""
                                    if (p.indexOf("/") >= 0) {
                                        var parts = p.split("/").filter(function(x){ return x !== "" })
                                        if (parts.length > 0) parts.pop()
                                        var parentPath = parts.length > 0 ? "/" + parts.join("/") : "/"
                                        segRow.siblings = fsBackend.getSubdirectories(parentPath)
                                    }
                                    var chosen = nativeMenu.showSiblingsMenu(segRow.siblings)
                                    if (chosen) root.segmentClicked(chosen)
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        // ── Search box ───────────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 200; Layout.preferredHeight: 26
            color: root.pal.content
            border.color: searchFld.activeFocus ? root.pal.accent : root.pal.borderSoft
            radius: 3

            TextField {
                id: searchFld
                anchors.fill: parent; anchors.rightMargin: 26
                placeholderText: root.currentFolderName ? "Buscar en " + root.currentFolderName : "Buscar"
                background: Item {}
                color: root.pal.text; font.pixelSize: 12; leftPadding: 8
                onTextChanged: root.searchChanged(text)
            }
            Canvas {
                anchors.right: parent.right; anchors.rightMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 14
                property color fg: root.pal.muted
                onFgChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, 14, 14); ctx.strokeStyle = fg
                    ctx.lineWidth = 1.6; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.arc(6, 6, 4, 0, Math.PI * 2); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(9, 9); ctx.lineTo(12.5, 12.5); ctx.stroke()
                }
            }
        }
    }
}
