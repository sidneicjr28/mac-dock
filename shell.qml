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
        model: Quickshell.screens
        Dock {
            required property var modelData
            screen: modelData
            config: appConfig.values
            model: dockModel
            catalog: appCatalog
            tracker: windowTracker
            onOpenSettings: settingsWindow.open()
        }
    }

    SettingsWindow { id: settingsWindow; config: appConfig.values; model: dockModel; catalog: appCatalog }

    // `qs -p <dir> ipc call dock settings` (bindable to a keyboard shortcut)
    IpcHandler {
        target: "dock"
        function settings(): void { settingsWindow.open() }
    }
}
