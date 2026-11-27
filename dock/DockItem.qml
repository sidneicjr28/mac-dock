import Quickshell
import QtQuick

// One dock slot: an app icon (with running dot and launch bounce) or a separator line.
// Geometry is set by Dock; `edge` orients the separator, the running dot and the bounce.
Item {
    id: root
    required property var item          // { id, pinned, sep } from DockModel
    required property var catalog
    required property var tracker
    required property var dockModel
    property string edge: "bottom"
    property bool dragged: false
    property bool fadeOut: false         // being dragged off the dock (will unpin)
    property bool animateSlots: false

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool isSeparator: item.sep
    readonly property var entry: isSeparator ? null : catalog.entryFor(item.id)
    readonly property var windows: isSeparator ? [] : tracker.windowsOf(item.id)
    readonly property bool running: windows.length > 0
    readonly property string label: entry?.name ?? windows[0]?.title ?? item.id
    property real bounce: 0

    z: dragged ? 10 : 0
    Behavior on x {
        enabled: root.animateSlots && !root.dragged
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        enabled: root.animateSlots && !root.dragged
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Left click: launch, or focus/cycle/minimize its windows. Middle click: always a new instance.
    function trigger(button) {
        if (!isSeparator) dockModel.activate(item.id, button === Qt.MiddleButton)
    }

    Connections {
        target: root.dockModel
        function onLaunched(id) { if (id === root.item.id && !root.running) bounceAnim.restart() }
    }

    Rectangle {
        visible: root.isSeparator
        anchors.centerIn: parent
        width: root.vertical ? parent.width * 0.8 : 1
        height: root.vertical ? 1 : parent.height * 0.8
        color: Qt.rgba(1, 1, 1, 0.22)
    }

    Image {
        visible: !root.isSeparator
        anchors.fill: parent
        source: root.isSeparator ? "" : root.catalog.iconFor(root.item.id)
        sourceSize: Qt.size(192, 192)   // constant: changing it reloads icons, and reloads can get lost
        smooth: true
        mipmap: true
        opacity: root.dragged && root.fadeOut ? 0.35 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }
        // Bounce away from the screen edge.
        transform: Translate {
            x: root.edge === "left" ? root.bounce : root.edge === "right" ? -root.bounce : 0
            y: root.edge === "top" ? root.bounce : root.edge === "bottom" ? -root.bounce : 0
        }
    }

    // Running indicator, between the icon and the screen edge.
    Rectangle {
        visible: root.running
        width: 5; height: 5; radius: 2.5
        color: Qt.rgba(1, 1, 1, 0.9)
        x: root.edge === "left" ? -width - 2 : root.edge === "right" ? parent.width + 2 : (parent.width - width) / 2
        y: root.edge === "top" ? -height - 2 : root.edge === "bottom" ? parent.height + 2 : (parent.height - height) / 2
    }

    SequentialAnimation {
        id: bounceAnim
        loops: 3
        NumberAnimation { target: root; property: "bounce"; to: 20; duration: 280; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounce"; to: 0; duration: 280; easing.type: Easing.InQuad }
    }
    onRunningChanged: if (running && bounceAnim.running) bounceAnim.complete()
}
