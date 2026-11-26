import Quickshell
import Quickshell.Io
import QtQuick

// Open windows, via bridge/windows.py (KWin has no wlr-foreign-toplevel; this uses
// org_kde_plasma_window_management). Window objects: { uuid, appId, title, pid, active, minimized }.
Scope {
    id: root
    required property var catalog

    property var windows: []

    readonly property var runningKeys: {
        const keys = []
        for (const w of windows) {
            const key = catalog.keyForAppId(w.appId)
            if (key && !keys.includes(key)) keys.push(key)
        }
        return keys
    }

    function windowsOf(key) { return windows.filter(w => catalog.keyForAppId(w.appId) === key) }

    function activate(w) { bridge.write(`activate ${w.uuid}\n`) }
    function minimize(w) { bridge.write(`minimize ${w.uuid}\n`) }

    // macOS-like click: raise the app, cycle through its windows, or minimize its only window.
    function focusOrCycle(appWindows) {
        if (!appWindows.length) return
        const i = appWindows.findIndex(w => w.active)
        if (i < 0) activate(appWindows[appWindows.length - 1])
        else if (appWindows.length > 1) activate(appWindows[(i + 1) % appWindows.length])
        else minimize(appWindows[i])
    }

    SupervisedProcess {
        id: bridge
        name: "windows.py"
        command: ["python3", Quickshell.shellPath("bridge/windows.py")]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try { root.windows = JSON.parse(line) }
                catch (e) { console.warn("windows.py sent invalid JSON:", line, e) }
            }
        }
        onStderrLine: line => console.warn("windows.py:", line)
    }
}
