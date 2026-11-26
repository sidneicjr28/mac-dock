import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// A labelled row; children are laid out to the right of the label.
RowLayout {
    property alias label: caption.text
    Layout.fillWidth: true
    spacing: 12
    Label { id: caption; Layout.preferredWidth: 150 }
}
