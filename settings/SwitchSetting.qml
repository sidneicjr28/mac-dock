import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

// Switch bound to one boolean config key, with an optional hint.
SettingRow {
    id: row
    required property var config
    required property string key
    property string hint: ""

    Switch {
        checked: row.config[row.key]
        onToggled: row.config[row.key] = checked
    }
    Label { visible: !!row.hint; text: row.hint; opacity: 0.6 }
}
