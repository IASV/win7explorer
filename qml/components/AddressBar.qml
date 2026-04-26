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
    signal searchChanged(string text)

    border.color: pal.borderSoft
    gradient: Gradient {
        GradientStop { position: 0; color: pal.tbar1 }
        GradientStop { position: 1; color: pal.tbar2 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10; anchors.rightMargin: 10
        anchors.topMargin: 6;   anchors.bottomMargin: 6
        spacing: 6

        // Nav buttons: back · forward · up
        RowLayout {
            spacing: 2
            Repeater {
                model: [
                    { pts: [[9,2],[4,7],[9,12]], clr: "accent",
                      get enabled() { return root.canGoBack },
                      action: function(){ root.backRequested() } },
                    { pts: [[5,2],[10,7],[5,12]], clr: "accent",
                      get enabled() { return root.canGoForward },
                      action: function(){ root.forwardRequested() } },
                    { pts: [[2,9],[7,4],[12,9]], clr: "muted",
                      get enabled() { return root.canGoUp },
                      action: function(){ root.upRequested() } }
                ]
                delegate: Rectangle {
                    Layout.preferredWidth: 26; Layout.preferredHeight: 26
                    radius: 13
                    color: btnMa.containsMouse && modelData.enabled ? root.pal.accentSoft : "transparent"
                    border.color: btnMa.containsMouse && modelData.enabled ? root.pal.border : "transparent"
                    opacity: modelData.enabled ? 1.0 : 0.35

                    Canvas {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        property var pts: modelData.pts
                        property color fg: modelData.clr === "accent" ? root.pal.accent : root.pal.muted
                        onFgChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, 14, 14)
                            ctx.strokeStyle = fg; ctx.lineWidth = 1.8
                            ctx.lineCap = "round"; ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(pts[0][0], pts[0][1])
                            ctx.lineTo(pts[1][0], pts[1][1])
                            ctx.lineTo(pts[2][0], pts[2][1])
                            ctx.stroke()
                        }
                    }
                    MouseArea {
                        id: btnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: modelData.enabled
                        onClicked: modelData.action()
                    }
                }
            }
        }

        // Breadcrumb bar
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 26
            color: root.pal.content; border.color: root.pal.borderSoft; radius: 3; clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4; anchors.rightMargin: 4
                spacing: 0

                Repeater {
                    model: root.pathToCurrent
                    delegate: RowLayout {
                        spacing: 0

                        Canvas {
                            visible: index > 0
                            Layout.preferredWidth: 8; Layout.preferredHeight: 10
                            property color fg: root.pal.muted
                            onFgChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, 8, 10)
                                ctx.strokeStyle = fg; ctx.lineWidth = 1.4; ctx.lineCap = "round"
                                ctx.beginPath(); ctx.moveTo(2, 1); ctx.lineTo(6, 5); ctx.lineTo(2, 9); ctx.stroke()
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: 20
                            color: crumbMa.containsMouse ? root.pal.accentSoft : "transparent"
                            radius: 2
                            implicitWidth: crumbLbl.implicitWidth + 14

                            Label {
                                id: crumbLbl
                                anchors.centerIn: parent
                                text: modelData.name
                                color: crumbMa.containsMouse ? root.pal.accent : root.pal.text
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: crumbMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.segmentClicked(modelData.path || modelData.id)
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        // Search box
        Rectangle {
            Layout.preferredWidth: 200; Layout.preferredHeight: 26
            color: root.pal.content
            border.color: searchFld.activeFocus ? root.pal.accent : root.pal.borderSoft
            radius: 3

            TextField {
                id: searchFld
                anchors.fill: parent; anchors.rightMargin: 26
                placeholderText: "Buscar"
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
