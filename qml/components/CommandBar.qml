import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var    pal
    property int    selectedCount: 0
    property bool   showPreview:       false
    property string viewMode:          "large"
    property string selectedItemType:  "none"

    signal organizeClicked
    signal openClicked
    signal shareClicked
    signal printClicked
    signal emailClicked
    signal slideShowClicked
    signal playClicked
    signal libraryClicked
    signal deleteRequested
    signal newFolderRequested
    signal previewToggled
    signal viewModeChangeRequested(string mode)
    signal helpClicked

    border.color: pal.borderSoft
    gradient: Gradient {
        GradientStop { position: 0; color: pal.tbar1 }
        GradientStop { position: 1; color: pal.tbar2 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8; anchors.rightMargin: 8
        anchors.topMargin: 4;  anchors.bottomMargin: 4
        spacing: 2

        Repeater {
            model: [
                { label: "Organizar",             chevron: true, always: true, visFor: null,
                  action: function(){ root.organizeClicked() } },
                { sep: true, visFor: null },
                { label: "Incluir en biblioteca", chevron: true, visFor: ["folder","drive"],
                  action: function(){ root.libraryClicked() } },
                { label: "Abrir",                 chevron: true, visFor: ["document","generic"],
                  action: function(){ root.openClicked() } },
                { label: "Compartir con",         visFor: ["folder","drive","document","generic"],
                  action: function(){ root.shareClicked() } },
                { label: "Presentación",          visFor: ["image"],
                  action: function(){ root.slideShowClicked() } },
                { label: "Reproducir",            visFor: ["audio","video"],
                  action: function(){ root.playClicked() } },
                { label: "Imprimir",              visFor: ["image","document"],
                  action: function(){ root.printClicked() } },
                { label: "Correo",                visFor: ["image","audio","video","document","generic"],
                  action: function(){ root.emailClicked() } },
                { label: "Eliminar",              visFor: ["folder","drive","image","audio","video","document","generic"],
                  action: function(){ root.deleteRequested() } },
                { sep: true, visFor: null },
                { label: "Nueva carpeta",         always: true, visFor: null,
                  action: function(){ root.newFolderRequested() } }
            ]
            delegate: Loader {
                readonly property bool shouldShow: !modelData.visFor ||
                    (root.selectedCount > 0 && modelData.visFor.indexOf(root.selectedItemType) >= 0)
                visible: shouldShow
                Layout.preferredWidth: shouldShow ? -1 : 0
                Layout.maximumWidth:   shouldShow ? Number.POSITIVE_INFINITY : 0
                sourceComponent: modelData.sep ? sepComp : btnComp

                Component {
                    id: sepComp
                    Rectangle { implicitWidth: 1; implicitHeight: 18; color: root.pal.border }
                }
                Component {
                    id: btnComp
                    Rectangle {
                        property bool isEnabled: modelData.always || root.selectedCount > 0
                        implicitWidth:  btnRow.implicitWidth + 16
                        implicitHeight: 26
                        color: btnMa.containsMouse && isEnabled ? root.pal.accentSoft : "transparent"
                        border.color: btnMa.containsMouse && isEnabled ? root.pal.border : "transparent"
                        radius: 2
                        opacity: isEnabled ? 1 : 0.4

                        Row {
                            id: btnRow
                            anchors.centerIn: parent
                            spacing: 3
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: root.pal.text
                                font.pixelSize: 12; font.bold: modelData.bold || false
                            }
                            Rectangle {
                                visible: modelData.chevron || false
                                width: 1; height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.pal.border
                            }
                            Canvas {
                                visible: modelData.chevron || false
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8; height: 6
                                property color fg: root.pal.muted
                                onFgChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0,0,8,6); ctx.strokeStyle=fg; ctx.lineWidth=1.3; ctx.lineCap="round"
                                    ctx.beginPath(); ctx.moveTo(1,1.5); ctx.lineTo(4,4.5); ctx.lineTo(7,1.5); ctx.stroke()
                                }
                            }
                        }
                        MouseArea {
                            id: btnMa; anchors.fill: parent; hoverEnabled: true
                            enabled: parent.isEnabled
                            onClicked: modelData.action()
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Preview panel toggle
        Rectangle {
            Layout.preferredWidth: 28; Layout.preferredHeight: 26
            color: prevMa.containsMouse || root.showPreview ? root.pal.accentSoft : "transparent"
            border.color: prevMa.containsMouse || root.showPreview ? root.pal.border : "transparent"
            radius: 2
            Canvas {
                anchors.centerIn: parent; width: 18; height: 14
                property color fg: root.pal.muted
                onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,18,14); ctx.strokeStyle=fg; ctx.lineWidth=1.2
                    ctx.strokeRect(0.5,0.5,17,13)
                    ctx.fillStyle=Qt.rgba(parseInt(fg.toString().slice(1,3),16)/255,
                                          parseInt(fg.toString().slice(3,5),16)/255,
                                          parseInt(fg.toString().slice(5,7),16)/255, 0.18)
                    ctx.fillRect(10,0.5,7.5,13)
                }
            }
            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.previewToggled() }
        }

        // View switcher
        Row {
            spacing: 0
            Rectangle {
                width: 28; height: 26
                color: vsIconMa.containsMouse ? root.pal.accentSoft : "transparent"
                border.color: vsIconMa.containsMouse ? root.pal.border : "transparent"
                radius: 2
                Canvas {
                    anchors.centerIn: parent; width: 16; height: 16
                    property string vm: root.viewMode
                    property color fg: root.pal.muted
                    onVmChanged: requestPaint(); onFgChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,16,16); ctx.fillStyle=fg; var m=vm
                        if (m==="xlarge") {
                            ctx.fillRect(1,1,6,6); ctx.fillRect(9,1,6,6)
                            ctx.fillRect(1,9,6,6); ctx.fillRect(9,9,6,6)
                        } else if (m==="large"||m==="medium") {
                            var s=m==="large"?4.5:3.5, xs=[1,8-s/2,15-s], ys=[1,8-s/2]
                            for (var yi=0;yi<ys.length;yi++) for (var xi=0;xi<xs.length;xi++) ctx.fillRect(xs[xi],ys[yi],s,s)
                        } else if (m==="small") {
                            for (var r=0;r<4;r++) { ctx.fillRect(1,1+r*4,2,2); ctx.fillRect(4,1.5+r*4,8,1); ctx.fillRect(9,1+r*4,2,2); ctx.fillRect(12,1.5+r*4,3,1) }
                        } else if (m==="list") {
                            ctx.fillRect(1,2,3,3); ctx.fillRect(5,3,10,1); ctx.fillRect(1,7,3,3); ctx.fillRect(5,8,10,1); ctx.fillRect(1,12,3,3); ctx.fillRect(5,13,10,1)
                        } else if (m==="tiles") {
                            ctx.fillRect(1,1,6,7); ctx.fillRect(8,2,7,1); ctx.fillRect(8,4,5,1)
                            ctx.fillRect(1,9,6,7); ctx.fillRect(8,10,7,1); ctx.fillRect(8,12,5,1)
                        } else if (m==="details") {
                            ctx.fillRect(1,2,2,2); ctx.fillRect(4,2.5,11,1); ctx.fillRect(1,6,2,2); ctx.fillRect(4,6.5,11,1); ctx.fillRect(1,10,2,2); ctx.fillRect(4,10.5,11,1)
                        } else {
                            ctx.fillRect(1,2,4,4); ctx.fillRect(6,2.5,9,1); ctx.fillRect(6,4.5,7,1); ctx.fillRect(1,8,4,4); ctx.fillRect(6,8.5,9,1); ctx.fillRect(6,10.5,7,1)
                        }
                    }
                }
                MouseArea {
                    id: vsIconMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: { var m = nativeMenu.showViewDropdown(root.viewMode); if (m) root.viewModeChangeRequested(m) }
                }
            }
            Rectangle {
                width: 16; height: 26
                color: vsChevMa.containsMouse ? root.pal.accentSoft : "transparent"
                border.color: vsChevMa.containsMouse ? root.pal.border : "transparent"
                radius: 2
                Canvas {
                    anchors.centerIn: parent; width: 8; height: 6
                    property color fg: root.pal.muted
                    onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                    onPaint: {
                        var ctx=getContext("2d"); ctx.clearRect(0,0,8,6); ctx.strokeStyle=fg; ctx.lineWidth=1.3; ctx.lineCap="round"
                        ctx.beginPath(); ctx.moveTo(1,1.5); ctx.lineTo(4,4.5); ctx.lineTo(7,1.5); ctx.stroke()
                    }
                }
                MouseArea {
                    id: vsChevMa; anchors.fill: parent; hoverEnabled: true
                    onClicked: { var m = nativeMenu.showViewDropdown(root.viewMode); if (m) root.viewModeChangeRequested(m) }
                }
            }
        }

        // Help button
        Rectangle {
            Layout.preferredWidth: 28; Layout.preferredHeight: 26
            color: helpMa.containsMouse ? root.pal.accentSoft : "transparent"
            border.color: helpMa.containsMouse ? root.pal.border : "transparent"
            radius: 2
            Canvas {
                anchors.centerIn: parent; width: 16; height: 16
                property color fg: root.pal.muted
                onFgChanged: requestPaint(); Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx=getContext("2d"); ctx.clearRect(0,0,16,16); ctx.strokeStyle=fg; ctx.lineWidth=1.4; ctx.lineCap="round"
                    ctx.beginPath(); ctx.arc(8,8,6.5,0,Math.PI*2); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(6,6); ctx.quadraticCurveTo(6,4,8,4); ctx.quadraticCurveTo(10,4,10,6); ctx.quadraticCurveTo(10,7.5,8,8); ctx.lineTo(8,9.5); ctx.stroke()
                    ctx.fillStyle=fg; ctx.beginPath(); ctx.arc(8,12,0.8,0,Math.PI*2); ctx.fill()
                }
            }
            MouseArea { id: helpMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.helpClicked() }
        }
    }
}
