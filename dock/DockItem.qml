import Quickshell
import QtQuick

// One dock slot: an app icon (with running dot and launch bounce) or a separator line.
Item {
    id: root
    required property var item          // { id, pinned, sep } from DockModel
    required property var catalog
    required property var tracker
    property real size
    property real slotX
    property real restSize               // separator height
    property real bottomY                // y of the icons' baseline
    property bool dragged: false
    property real dragX: 0
    property bool fadeOut: false         // being dragged off the dock (will unpin)
    property bool animateSlots: false

    readonly property bool isSeparator: item.sep
    readonly property var entry: isSeparator ? null : catalog.entryFor(item.id)
    readonly property var windows: isSeparator ? [] : tracker.windowsOf(item.id)
    readonly property bool running: windows.length > 0
    readonly property string label: entry?.name ?? windows[0]?.title ?? item.id
    property real bounce: 0

    width: size
    height: isSeparator ? restSize : size
    x: dragged ? dragX - size / 2 : slotX
    y: bottomY - height - (dragged ? 12 : 0)
    z: dragged ? 10 : 0
    Behavior on x {
        enabled: root.animateSlots && !root.dragged
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Left click: launch, or focus/cycle/minimize its windows. Middle click: always a new instance.
    function trigger(button) {
        if (isSeparator) return
        if (button === Qt.MiddleButton || !running) launch()
        else tracker.focusOrCycle(windows)
    }

    function launch() {
        if (!entry) return
        entry.execute()
        if (!running) bounceAnim.restart()
    }

    Rectangle {
        visible: root.isSeparator
        anchors.centerIn: parent
        width: 1
        height: parent.height * 0.8
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
        transform: Translate { y: -root.bounce }
    }

    Rectangle {
        visible: root.running
        width: 5; height: 5; radius: 2.5
        color: Qt.rgba(1, 1, 1, 0.9)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 2
    }

    SequentialAnimation {
        id: bounceAnim
        loops: 3
        NumberAnimation { target: root; property: "bounce"; to: 20; duration: 280; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounce"; to: 0; duration: 280; easing.type: Easing.InQuad }
    }
    onRunningChanged: if (running && bounceAnim.running) bounceAnim.complete()
}
