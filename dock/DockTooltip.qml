import QtQuick

// App-name bubble above the hovered icon. Keeps its last text while fading out.
Rectangle {
    id: tip
    property Item target: null
    property string text: ""

    onTargetChanged: if (target) text = target.label

    opacity: target ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
    width: label.implicitWidth + 20
    height: 26
    radius: 9
    x: target ? target.x + target.width / 2 - width / 2 : x
    y: target ? target.y - height - 10 : y
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
