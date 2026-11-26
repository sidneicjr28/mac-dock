# Mac Dock

A macOS-style glass dock for **KDE Plasma 6 (Wayland)**, built with [Quickshell](https://quickshell.org).

- Gaussian icon magnification on hover, launch bounce, running-app dots
- Drag to reorder pinned apps; drag up and release to unpin
- Separators to group pinned apps; unpinned running apps appear after a divider
- Real background blur through KWin's Glass effect, with a glass highlight rim
- Per-screen auto-scaling for lower-resolution monitors
- Super+1…9 open (or focus/cycle) the first nine apps on the dock
- Right-click menu (pin/unpin, settings) and a settings window (size, magnification, colors, blur, apps)

## Requirements

- KDE Plasma 6 on Wayland
- `quickshell`
- `python-pywayland` (window list bridge)
- `python-dbus`, `python-gobject` (global shortcuts)
- KWin **Glass** effect (`Effect-blurplus` settings) for the blur

## Run

```sh
qs -p /path/to/mac-dock
```

Autostart: add `~/.config/autostart/mac-dock.desktop` with `Exec=qs -p /path/to/mac-dock`.

Open settings by right-clicking the dock, left-clicking an empty part of the bar, or:

```sh
qs -p /path/to/mac-dock ipc call dock settings
```

Settings are stored in `config.json` (created on first run).

## Glass blur setup

The dock window is excluded from Glass's force-blur and a separate, bar-sized window carries the blur:

```sh
kwriteconfig6 --file kwinrc --group Effect-blurplus --key WindowClasses quickshell
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect glass
```

The dock keeps `DockCornerRadius` and `DockBlurStrength` in sync with its own settings.

## Architecture

| Path | Responsibility |
|---|---|
| `shell.qml` | Composition root: creates services once and injects them into views |
| `services/Config.qml` | Persistent settings (`config.json`) and defaults |
| `services/AppCatalog.qml` | App id → desktop entry / icon resolution |
| `services/WindowTracker.qml` | Open windows and focus/cycle/minimize actions |
| `services/DockModel.qml` | Dock items (pinned groups + running apps) and all pin edits |
| `services/SupervisedProcess.qml` | Helper processes that restart on exit |
| `services/GlassProcess.qml` | Launches the blur window under its own window class |
| `services/KwinGlassSync.qml` | Mirrors radius/blur strength into kwinrc |
| `dock/` | Dock view: layout, input, icons, rim, tooltip, menu; `Magnify.js` holds the pure layout math |
| `settings/` | Settings window, one file per page plus reusable config-bound controls |
| `glass/shell.qml` | The bar-sized blur window (separate process) |
| `bridge/shortcuts.py` | Registers Super+1…9 with KDE's KGlobalAccel (releasing Plasma's task-manager bindings) and reports presses |
| `bridge/windows.py` | KWin `org_kde_plasma_window_management` → JSON bridge (KWin lacks wlr-foreign-toplevel) |

`bridge/protocols/plasma-window-management.xml` is from KDE's
[plasma-wayland-protocols](https://invent.kde.org/libraries/plasma-wayland-protocols) (LGPL-2.1-or-later);
`bridge/pwm_proto.py` is generated from it with the pywayland scanner.
