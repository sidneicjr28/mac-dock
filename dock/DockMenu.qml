import Quickshell
import QtQuick

// Context menu popup. Generic: callers pass [{ text, run }] actions.
// grabFocus makes it an xdg_popup grab, so clicking anywhere else closes it.
PopupWindow {
    id: menu
    property var actions: []

    // Show at (x, y) in parent-window coordinates, opening away from the dock's screen edge;
    // the compositor slides it back on screen if needed.
    function show(items, x, y, dockEdge) {
        actions = items
        const away = { bottom: Edges.Top, top: Edges.Bottom, left: Edges.Right, right: Edges.Left }[dockEdge]
        anchor.edges = away
        anchor.gravity = away
        anchor.rect.x = Math.round(x)
        anchor.rect.y = Math.round(y)
        visible = true
    }

    anchor.rect.width: 1
    anchor.rect.height: 1
    grabFocus: true
    color: "transparent"
    implicitWidth: 190
    implicitHeight: column.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(0.12, 0.12, 0.14, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.18)

        Column {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }

            Repeater {
                model: menu.actions
                Rectangle {
                    required property var modelData
                    width: column.width
                    height: 28
                    radius: 6
                    color: hover.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10
                        text: modelData.text
                        color: "#f2f2f2"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const run = modelData.run
                            menu.visible = false
                            run()
                        }
                    }
                }
            }
        }
    }
}
