import Quickshell
import Quickshell.Io
import QtQuick
import "Defaults.js" as Defaults

// User settings persisted to config.json (created with Defaults.js values on first run).
Scope {
    readonly property alias values: adapter

    // Every setting back to its default except the pinned apps. Written as one file update:
    // assigning keys one by one writes after each, and the reloads race the later assignments.
    function restoreDefaults() {
        const next = Object.assign({}, Defaults.values, { pinned: Array.from(adapter.pinned) })
        file.setText(JSON.stringify(next, null, 4))
    }

    FileView {
        id: file
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter()
            else console.warn("config.json could not be loaded:", FileViewError.toString(error))
        }

        JsonAdapter {
            id: adapter
            property list<string> pinned: Defaults.values.pinned
            property int iconSize: Defaults.values.iconSize
            property real magnification: Defaults.values.magnification
            property int padding: Defaults.values.padding
            property int spacing: Defaults.values.spacing
            property int margin: Defaults.values.margin
            property int cornerRadius: Defaults.values.cornerRadius
            property bool autoScale: Defaults.values.autoScale
            property string bgColor: Defaults.values.bgColor
            property real bgOpacity: Defaults.values.bgOpacity
            property bool blur: Defaults.values.blur
            property int blurStrength: Defaults.values.blurStrength
            property real rimOpacity: Defaults.values.rimOpacity
            property bool showRunning: Defaults.values.showRunning
            property string position: Defaults.values.position
            property bool autoHide: Defaults.values.autoHide
            property string screen: Defaults.values.screen
        }
    }
}
