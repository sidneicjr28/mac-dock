// Composition root: creates the shared services once and injects them into the views.
import Quickshell
import Quickshell.Io
import QtQuick
import "services"
import "dock"
import "settings"

ShellRoot {
    // Ids differ from the injected property names so `catalog: appCatalog` can't bind to itself.
    Config { id: appConfig }
    AppCatalog { id: appCatalog }
    WindowTracker { id: windowTracker; catalog: appCatalog }
    DockModel { id: dockModel; config: appConfig.values; catalog: appCatalog; tracker: windowTracker }

    GlassProcess {}
    KwinGlassSync { config: appConfig.values }

    Variants {
        // One screen if chosen and connected, otherwise all of them.
        model: {
            const chosen = Quickshell.screens.filter(s => s.name === appConfig.values.screen)
            return chosen.length ? chosen : Quickshell.screens
        }
        Dock {
            required property var modelData
            screen: modelData
            config: appConfig.values
            model: dockModel
            catalog: appCatalog
            tracker: windowTracker
            onOpenSettings: settings.open()
        }
    }

    // Super+1..9 open the first nine dock apps (registered with KDE's KGlobalAccel).
    SupervisedProcess {
        name: "shortcuts.py"
        command: ["python3", Quickshell.shellPath("bridge/shortcuts.py")]
        stdout: SplitParser { onRead: line => dockModel.activateSlot(parseInt(line)) }
        onStderrLine: line => console.warn(line)
    }

    // Built on first open: the settings UI (Controls, app list, icons) is rarely used.
    LazyLoader {
        id: settings
        function open() { active = true; item.open() }
        SettingsWindow { config: appConfig.values; model: dockModel; catalog: appCatalog }
    }
    // Unload once closed. Deferred: open() toggles visible off and on synchronously.
    Connections {
        target: settings.item
        function onVisibleChanged() {
            Qt.callLater(() => { if (settings.item && !settings.item.visible) settings.active = false })
        }
    }

    // `qs -p <dir> ipc call dock settings` (bindable to a keyboard shortcut)
    IpcHandler {
        target: "dock"
        function settings(): void { settings.open() }
        function activate(slot: int): void { dockModel.activateSlot(slot) }
    }
}
