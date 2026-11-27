import Quickshell
import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

FloatingWindow {
    id: win
    required property var config     // Config.values
    required property var model      // DockModel
    required property var catalog    // AppCatalog
    signal restoreDefaults()

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

        // Not a StackLayout: it skips resizing hidden pages, so they keep a stale width.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            AppearancePage { anchors.fill: parent; visible: tabs.currentIndex === 0; config: win.config }
            AppsPage { anchors.fill: parent; visible: tabs.currentIndex === 1; config: win.config; model: win.model; catalog: win.catalog }
            AboutPage { anchors.fill: parent; visible: tabs.currentIndex === 2 }
        }

        RowLayout {
            Label {
                text: "Tip: drag icons on the dock to reorder; drag one off the dock and release to unpin. Right-click for options."
                opacity: 0.6
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Button { text: "Restore Defaults"; onClicked: confirmReset.open() }
            Button { text: "Close"; onClicked: win.visible = false }
        }
    }

    Dialog {
        id: confirmReset
        title: "Restore defaults?"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.RestoreDefaults | Dialog.Cancel
        Label { text: "All settings go back to their defaults.\nYour pinned apps are kept." }
        onReset: { win.restoreDefaults(); close() }
    }
}
