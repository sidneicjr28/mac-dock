import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// Preset swatches plus a hex field, bound to one "#rrggbb" config key.
SettingRow {
    id: row
    required property var config
    required property string key
    property var presets: ["#000000", "#1d1d1f", "#ffffff", "#3a3a5c", "#0a3d62", "#4a1c40"]
    readonly property string current: String(config[key]).toLowerCase()

    SystemPalette { id: pal }

    Repeater {
        model: row.presets
        Rectangle {
            required property string modelData
            readonly property bool selected: row.current === modelData
            width: 24; height: 24; radius: 12
            color: modelData
            border.width: selected ? 3 : 1
            border.color: selected ? pal.highlight : pal.mid
            MouseArea { anchors.fill: parent; onClicked: row.config[row.key] = parent.modelData }
        }
    }
    TextField {
        Layout.preferredWidth: 90
        text: row.config[row.key]
        validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{6}/ }
        onEditingFinished: if (acceptableInput) row.config[row.key] = text
    }
}
