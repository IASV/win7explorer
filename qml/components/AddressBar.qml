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

        Item { Layout.preferredWidth: 4 }

        // ── Up button (wider image) ──────────────────────────────────────
        Item {
            Layout.preferredWidth: 36; Layout.preferredHeight: 27

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: {
                    if (!root.canGoUp)       return "qrc:/icons/nav-up-disabled.png"
                    if (upMa.pressed)        return "qrc:/icons/nav-up-pressed.png"
                    if (upMa.containsMouse)  return "qrc:/icons/nav-up-hover.png"
                    return "qrc:/icons/nav-up-normal.png"
                }
            }
            MouseArea {
                id: upMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.canGoUp
                cursorShape: root.canGoUp ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.upRequested()
            }
        }

        // ── Breadcrumb bar ───────────────────────────────────────────────
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

                        // Separator chevron between segments
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

        // ── Search box ───────────────────────────────────────────────────
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
