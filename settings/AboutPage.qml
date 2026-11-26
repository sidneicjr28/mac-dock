import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

ColumnLayout {
    id: page
    readonly property string author: "sidneicjr28"
    readonly property string profileUrl: "https://github.com/sidneicjr28"
    spacing: 10

    SystemPalette { id: pal }

    Item { Layout.fillHeight: true }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: "Mac Dock"
        font.pixelSize: 26
        font.bold: true
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: "A macOS-style glass dock for KDE Plasma, built with Quickshell."
        opacity: 0.7
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 12
        text: `Created by <b>${page.author}</b>`
        textFormat: Text.StyledText
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: `<a href="${page.profileUrl}">${page.profileUrl.replace("https://", "")}</a>`
        textFormat: Text.StyledText
        linkColor: pal.highlight
        onLinkActivated: link => Qt.openUrlExternally(link)
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    Item { Layout.fillHeight: true }
}
