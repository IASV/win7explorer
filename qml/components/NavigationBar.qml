import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

// ═══════════════════════════════════════════════════
// Navigation Bar: [←] [→] [↑] [▼] | Breadcrumbs... | Search
// Replicates the Win7 Explorer top bar exactly
// ═══════════════════════════════════════════════════
Rectangle {
    id: navBar

    // Expose search text so main.qml can bind it to ContentArea.searchQuery
    property alias searchText: searchInput.text

    // Clear search box whenever we navigate to a new directory
    Connections {
        target: fileSystemBackend
        function onCurrentPathChanged() { searchInput.text = "" }
    }

    // Background gradient matching Win7
    gradient: Gradient {
        GradientStop { position: 0.0; color: Win7Theme.navBarGradientTop }
        GradientStop { position: 1.0; color: Win7Theme.navBarGradientBottom }
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Win7Theme.navBarBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 6
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        spacing: 2

        // ── Back Button (circular blue Aero button) ──
        AeroNavButton {
            id: backBtn
            iconSource: "qrc:/Win7Explorer/resources/icons/nav-back.svg"
            enabled: fileSystemBackend.canGoBack
            diameter: Win7Theme.navBtnSize
            isBack: true
            onClicked: fileSystemBackend.goBack()
            ToolTip.text: "Atrás"
            ToolTip.visible: hovered && enabled
        }

        // ── Forward Button ──
        AeroNavButton {
            id: forwardBtn
            iconSource: "qrc:/Win7Explorer/resources/icons/nav-forward.svg"
            enabled: fileSystemBackend.canGoForward
            diameter: Win7Theme.navBtnSize - 4
            onClicked: fileSystemBackend.goForward()
            ToolTip.text: "Adelante"
            ToolTip.visible: hovered && enabled
        }

        Item { width: 4 } // spacer

        // ── Up Button (small, not circular) ──
        Rectangle {
            id: upBtn
            width: 22
            height: 22
            radius: 2
            color: upBtnMa.containsPress ? Win7Theme.cmdBarBtnPressed
                 : upBtnMa.containsMouse ? Win7Theme.cmdBarBtnHover
                 : "transparent"
            border.color: upBtnMa.containsMouse ? Win7Theme.selectionBorder : "transparent"
            border.width: 1
            opacity: fileSystemBackend.canGoUp ? 1.0 : 0.4

            Text {
                anchors.centerIn: parent
                text: "↑"
                font.pixelSize: 14
                font.bold: true
                color: Win7Theme.cmdBarText
            }

            MouseArea {
                id: upBtnMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: fileSystemBackend.canGoUp
                onClicked: fileSystemBackend.goUp()
            }

            ToolTip.text: "Subir un nivel"
            ToolTip.visible: upBtnMa.containsMouse && fileSystemBackend.canGoUp
        }

        // ── Recent Locations Dropdown ──
        Rectangle {
            width: 16
            height: 22
            radius: 2
            color: recentMa.containsPress ? Win7Theme.cmdBarBtnPressed
                 : recentMa.containsMouse ? Win7Theme.cmdBarBtnHover
                 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "▾"
                font.pixelSize: 10
                color: Win7Theme.cmdBarText
            }

            MouseArea {
                id: recentMa
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Item { width: 2 }

        // ═══ Address Bar (Breadcrumbs) ═══
        Rectangle {
            id: addressBar
            Layout.fillWidth: true
            height: 24
            radius: 1
            color: Win7Theme.addressBarBg
            border.color: addressBarFocused ? Win7Theme.addressBarBorderFocused
                                            : Win7Theme.addressBarBorder
            border.width: 1

            property bool addressBarFocused: addressInput.activeFocus
            property bool editMode: false

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                spacing: 0
                visible: !addressBar.editMode

                // Folder icon
                Text {
                    text: "📁"
                    font.pixelSize: 12
                    Layout.leftMargin: 2
                }

                Item { width: 2 }

                // Breadcrumb segments
                Repeater {
                    model: fileSystemBackend.pathSegments

                    delegate: Row {
                        spacing: 0

                        // Separator arrow (except for first segment)
                        Text {
                            text: "▸"
                            font.pixelSize: 9
                            color: Win7Theme.breadcrumbSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            visible: index > 0
                            leftPadding: 2
                            rightPadding: 2
                        }

                        // Segment button
                        Rectangle {
                            height: 20
                            width: segmentLabel.implicitWidth + 8
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: segMa.containsPress ? Win7Theme.breadcrumbPressed
                                 : segMa.containsMouse ? Win7Theme.breadcrumbHover
                                 : "transparent"

                            Text {
                                id: segmentLabel
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: Win7Theme.fontFamily
                                font.pixelSize: Win7Theme.fontSizeNormal + 2
                                color: Win7Theme.breadcrumbText
                            }

                            MouseArea {
                                id: segMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: fileSystemBackend.navigateTo(modelData.path)
                            }
                        }
                    }
                }

                // Fill remaining space (clickable to enter edit mode)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            addressBar.editMode = true
                            addressInput.text = fileSystemBackend.currentPath
                            addressInput.forceActiveFocus()
                            addressInput.selectAll()
                        }
                    }
                }

                // Dropdown arrow
                Rectangle {
                    width: 18
                    height: parent.height - 2
                    color: dropdownMa.containsMouse ? Win7Theme.breadcrumbHover : "transparent"
                    border.color: dropdownMa.containsMouse ? Win7Theme.addressBarBorder : "transparent"
                    Layout.rightMargin: 0

                    Text {
                        anchors.centerIn: parent
                        text: "▾"
                        font.pixelSize: 8
                        color: Win7Theme.breadcrumbSeparator
                    }

                    MouseArea {
                        id: dropdownMa
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }

                // Refresh button
                Rectangle {
                    width: 20
                    height: parent.height - 2
                    color: refreshMa.containsMouse ? Win7Theme.breadcrumbHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⟳"
                        font.pixelSize: 12
                        color: Win7Theme.breadcrumbSeparator
                    }

                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: fileSystemBackend.refresh()
                    }
                }
            }

            // Edit mode: text input for direct path entry
            TextInput {
                id: addressInput
                anchors.fill: parent
                anchors.margins: 3
                visible: addressBar.editMode
                font.family: Win7Theme.fontFamily
                font.pixelSize: Win7Theme.fontSizeNormal + 2
                color: Win7Theme.breadcrumbText
                selectByMouse: true
                clip: true

                onAccepted: {
                    fileSystemBackend.navigateTo(text)
                    addressBar.editMode = false
                }
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        addressBar.editMode = false
                    }
                }

                Keys.onEscapePressed: {
                    addressBar.editMode = false
                    addressBar.forceActiveFocus()
                }
            }
        }

        Item { width: 2 }

        // ═══ Search Box ═══
        Rectangle {
            id: searchBox
            width: 180
            height: 24
            radius: 1
            color: Win7Theme.searchBoxBg
            border.color: searchInput.activeFocus ? Win7Theme.addressBarBorderFocused
                                                  : Win7Theme.searchBoxBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 0

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.family: Win7Theme.fontFamily
                    font.pixelSize: Win7Theme.fontSizeNormal + 2
                    color: Win7Theme.breadcrumbText
                    clip: true
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true

                    // Placeholder
                    Text {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar " + (fileSystemBackend.pathSegments.length > 0
                              ? fileSystemBackend.pathSegments[fileSystemBackend.pathSegments.length - 1].name
                              : "")
                        font: parent.font
                        color: Win7Theme.searchBoxPlaceholder
                        visible: !searchInput.text && !searchInput.activeFocus
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 2
                    }
                }

                // Search icon button
                Rectangle {
                    width: 22
                    height: parent.height
                    radius: 1
                    color: searchBtnMa.containsMouse ? Win7Theme.searchBtnHover
                                                     : Win7Theme.searchBtnBg

                    Text {
                        anchors.centerIn: parent
                        text: "🔍"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: searchBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }

    // ═══ Aero Navigation Button Component ═══
    component AeroNavButton: Rectangle {
        id: aeroBtn
        property alias iconSource: btnIcon.source
        property int diameter: Win7Theme.navBtnSize
        property bool isBack: false
        property alias hovered: btnMa.containsMouse
        signal clicked()

        width: diameter
        height: diameter
        radius: diameter / 2

        // Circular blue gradient
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: !aeroBtn.enabled ? Win7Theme.navBtnDisabled
                     : btnMa.containsPress ? Win7Theme.navBtnPressed
                     : btnMa.containsMouse ? Win7Theme.navBtnHover
                     : Win7Theme.navBtnNormal
            }
            GradientStop {
                position: 1.0
                color: !aeroBtn.enabled ? Qt.darker(Win7Theme.navBtnDisabled, 1.15)
                     : btnMa.containsPress ? Qt.darker(Win7Theme.navBtnPressed, 1.2)
                     : btnMa.containsMouse ? Qt.darker(Win7Theme.navBtnHover, 1.15)
                     : Qt.darker(Win7Theme.navBtnNormal, 1.2)
            }
        }

        border.color: aeroBtn.enabled ? Win7Theme.navBtnBorder
                                       : Win7Theme.navBtnBorderDisabled
        border.width: 1

        // Gloss/shine overlay on top half
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.45
            radius: parent.radius
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#50FFFFFF" }
                    GradientStop { position: 1.0; color: "#10FFFFFF" }
                }
            }
        }

        // Arrow icon
        Image {
            id: btnIcon
            anchors.centerIn: parent
            width: 14
            height: 14
            sourceSize: Qt.size(14, 14)
            visible: source.toString() !== ""
        }

        // Fallback text arrow if SVG not found
        Text {
            anchors.centerIn: parent
            text: aeroBtn.isBack ? "←" : "→"
            font.pixelSize: 14
            font.bold: true
            color: Win7Theme.navBtnArrow
            visible: !btnIcon.visible || btnIcon.status !== Image.Ready
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: aeroBtn.enabled
            onClicked: aeroBtn.clicked()
            cursorShape: aeroBtn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }
}
