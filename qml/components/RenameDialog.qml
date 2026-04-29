import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    property var pal
    property var item: null

    signal renameConfirmed(string oldPath, string newName)

    title:  "Cambiar nombre"
    modal:  true
    standardButtons: Dialog.Ok | Dialog.Cancel
    width:  360

    ColumnLayout {
        width: parent.width
        spacing: 8

        Label {
            text: "Nuevo nombre:"
            font.pixelSize: 12
            color: root.pal ? root.pal.text : "#000"
        }

        TextField {
            id: nameField
            Layout.fillWidth: true
            font.pixelSize: 12
            selectByMouse: true
            Keys.onReturnPressed: root.accept()
            Keys.onEscapePressed: root.reject()
        }
    }

    onOpened: {
        nameField.text = root.item ? (root.item.name || "") : ""
        nameField.selectAll()
        nameField.forceActiveFocus()
    }

    onAccepted: {
        var newName = nameField.text.trim()
        if (root.item && newName && newName !== root.item.name)
            root.renameConfirmed(root.item.id, newName)
    }
}
