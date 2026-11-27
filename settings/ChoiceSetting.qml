import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// Drop-down bound to one config key. options: [{ text, value }].
SettingRow {
    id: row
    required property var config
    required property string key
    property var options: []

    ComboBox {
        Layout.fillWidth: true
        model: row.options
        textRole: "text"
        valueRole: "value"
        currentIndex: Math.max(0, row.options.findIndex(o => o.value === row.config[row.key]))
        onActivated: row.config[row.key] = currentValue
    }
}
