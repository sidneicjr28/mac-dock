import Quickshell
import Quickshell.Io
import QtQuick

// User settings persisted to config.json (created with these defaults on first run).
Scope {
    readonly property alias values: adapter

    FileView {
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
            property list<string> pinned: ["org.kde.dolphin", "firefox", "org.kde.konsole", "|", "systemsettings"]
            property int iconSize: 48
            property real magnification: 1.75
            property int padding: 8
            property int spacing: 6
            property int margin: 6
            property int cornerRadius: 22
            property bool autoScale: true
            property string bgColor: "#000000"
            property real bgOpacity: 0
            property bool blur: true
            property int blurStrength: 4
            property real rimOpacity: 1
            property bool showRunning: true
        }
    }
}
