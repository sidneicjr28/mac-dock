import QtQuick

// App-name bubble beside the hovered icon, on the side away from the screen edge.
// Keeps its last text and position while fading out.
Rectangle {
    id: tip
    property Item target: null
    property string text: ""
    property string edge: "bottom"
    readonly property real gap: 10

    onTargetChanged: if (target) text = target.label

    opacity: target ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: label.implicitWidth + 20
    height: 26
    radius: 9
    x: !target ? x
        : edge === "left" ? target.x + target.width + gap
        : edge === "right" ? target.x - width - gap
        : target.x + target.width / 2 - width / 2
    y: !target ? y
        : edge === "top" ? target.y + target.height + gap
        : edge === "bottom" ? target.y - height - gap
        : target.y + target.height / 2 - height / 2
    color: Qt.rgba(1, 1, 1, 0.6)
    border.color: Qt.rgba(1, 1, 1, 0.22)

    Text {
        id: label
        anchors.centerIn: parent
        text: tip.text
        color: "#1d1d1f"
        font.pixelSize: 12
    }
}
