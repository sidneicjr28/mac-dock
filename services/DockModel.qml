import Quickshell
import QtQuick

// What the dock shows: pinned apps (grouped by separators) followed by unpinned running apps.
// Items: { id, pinned, sep }. Owns every change to the pinned list.
QtObject {
    id: root
    required property var config     // Config.values
    required property var catalog
    required property var tracker

    readonly property string separator: "|"

    readonly property var items: {
        DesktopEntries.applications.values.length   // re-evaluate once desktop entries load
        const pinned = Array.from(config.pinned).filter(id => id === separator || catalog.entryFor(id))
        const out = []
        for (const id of pinned) {
            const sep = id === separator
            if (sep && (!out.length || out[out.length - 1].sep)) continue   // no leading/double separators
            out.push({ id, pinned: true, sep })
        }
        if (out.length && out[out.length - 1].sep) out.pop()

        const unpinnedRunning = config.showRunning ? tracker.runningKeys.filter(k => !pinned.includes(k)) : []
        if (unpinnedRunning.length) {
            out.push({ id: "__running", pinned: false, sep: true })
            for (const id of unpinnedRunning) out.push({ id, pinned: false, sep: false })
        }
        return out
    }
    readonly property int pinnedCount: items.filter(it => it.pinned).length

    // A fresh launch, so views can play the launch bounce.
    signal launched(string id)

    // Launch the app, or focus/cycle/minimize its windows. `newInstance` always launches.
    function activate(id, newInstance) {
        const appWindows = tracker.windowsOf(id)
        if (appWindows.length && !newInstance) return tracker.focusOrCycle(appWindows)
        const entry = catalog.entryFor(id)
        if (!entry) return console.warn("No desktop entry to launch for", id)
        entry.execute()
        if (!appWindows.length) launched(id)
    }

    // Super+N: the Nth app on the dock (1-based, separators skipped).
    function activateSlot(n) {
        const app = items.filter(it => !it.sep)[n - 1]
        if (app) activate(app.id, false)
    }

    function isPinned(id) { return Array.from(config.pinned).includes(id) }

    function edit(mutate) {
        const list = Array.from(config.pinned)
        mutate(list)
        config.pinned = list
    }

    function pin(id) { if (!isPinned(id)) edit(l => l.push(id)) }
    function unpin(id) { edit(l => { const i = l.indexOf(id); if (i >= 0) l.splice(i, 1) }) }
    function removeAt(index) { edit(l => l.splice(index, 1)) }
    function move(from, to) { edit(l => l.splice(to, 0, l.splice(from, 1)[0])) }
    function addSeparator() { edit(l => l.push(separator)) }

    // Apply a drag on the dock: indices refer to the visible pinned items.
    function reorderVisible(from, to, remove) {
        const ids = items.filter(it => it.pinned).map(it => it.id)
        const [moved] = ids.splice(from, 1)
        if (!remove) ids.splice(to, 0, moved)
        config.pinned = ids
    }
}
