import Quickshell
import QtQuick

// Resolves app ids (desktop-file ids or Wayland app_ids) to desktop entries and icons.
QtObject {
    readonly property string fallbackIcon: "application-x-executable"

    function normalize(id) { return (id || "").replace(/\.desktop$/, "") }

    function entryFor(id) { return DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id) }

    // Windows report an app_id; map it to the desktop id used for pinning when one exists.
    function keyForAppId(appId) {
        const entry = DesktopEntries.heuristicLookup(appId)
        return entry ? normalize(entry.id) : appId
    }

    function iconFor(id) {
        return Quickshell.iconPath(entryFor(id)?.icon ?? id, fallbackIcon)
    }

    function launchable() {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .sort((a, b) => a.name.localeCompare(b.name))
    }
}
