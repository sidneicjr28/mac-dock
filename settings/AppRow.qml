import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// Icon + name row used by the app lists; extra children (buttons) go on the right.
RowLayout {
    id: row
    property alias icon: image.source
    property alias text: name.text
    property int iconSize: 24
    default property alias trailing: tail.data
    spacing: 8

    Image {
        id: image
        visible: source != ""
        sourceSize: Qt.size(row.iconSize, row.iconSize)
        Layout.preferredWidth: row.iconSize
        Layout.preferredHeight: row.iconSize
    }
    Label { id: name; Layout.fillWidth: true; elide: Text.ElideRight }
    RowLayout { id: tail; spacing: 0 }
}
