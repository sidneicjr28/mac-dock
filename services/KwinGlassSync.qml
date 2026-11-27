import Quickshell
import Quickshell.Io
import QtQuick

// The Glass KWin effect rounds and blurs Dock-type windows with its own DockCornerRadius and
// DockBlurStrength, so mirror those settings into kwinrc. Debounced: sliders change every step.
// Skipped when Glass isn't loaded: KWin's own Blur takes the radius from the glass window's
// blur region and keeps its global strength.
Scope {
    id: root
    required property var config     // Config.values

    Connections {
        target: root.config
        function onCornerRadiusChanged() { debounce.restart() }
        function onBlurStrengthChanged() { debounce.restart() }
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: if (!writer.running) writer.running = true
    }

    Process {
        id: writer
        command: ["sh", "-c",
            '[ "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded glass)" = true ] || exit 0; ' +
            'kwriteconfig6 --file kwinrc --group Effect-blurplus --key DockCornerRadius "$1" && ' +
            'kwriteconfig6 --file kwinrc --group Effect-blurplus --key DockBlurStrength "$2" && ' +
            'qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect glass',
            "sh", String(root.config.cornerRadius), String(root.config.blurStrength)]
        onExited: code => { if (code !== 0) console.warn("kwinrc sync failed with exit code", code) }
    }
}
