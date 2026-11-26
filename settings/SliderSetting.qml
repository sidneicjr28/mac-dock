import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// Slider bound to one numeric config key.
SettingRow {
    id: row
    required property var config
    required property string key
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property int decimals: 0

    Slider {
        id: slider
        Layout.fillWidth: true
        snapMode: Slider.SnapAlways
        value: row.config[row.key]
        onMoved: row.config[row.key] = value
    }
    Label {
        text: slider.value.toFixed(row.decimals)
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
    }
}
