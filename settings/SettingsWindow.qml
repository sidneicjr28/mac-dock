import Quickshell
import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

FloatingWindow {
    id: win
    required property var config     // Config.values
    required property var model      // DockModel
    required property var catalog    // AppCatalog

    visible: false
    title: "Dock Settings"
    implicitWidth: 520
    implicitHeight: 640
    color: pal.window

    // Closing via the window manager may leave `visible` true, so force a hide/show cycle.
    function open() {
        visible = false
        visible = true
    }

    SystemPalette { id: pal; colorGroup: SystemPalette.Active }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        TabBar {
            id: tabs
            Layout.fillWidth: true
            TabButton { text: "Appearance" }
            TabButton { text: "Apps" }
            TabButton { text: "About" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            AppearancePage { config: win.config }
            AppsPage { config: win.config; model: win.model; catalog: win.catalog }
            AboutPage {}
        }

        RowLayout {
            Label {
                text: "Tip: drag icons on the dock to reorder; drag up and release to unpin. Right-click for options."
                opacity: 0.6
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Button { text: "Close"; onClicked: win.visible = false }
        }
    }
}
