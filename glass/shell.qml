// Bar-sized blur window, run by GlassProcess under a renamed quickshell binary.
// The Glass KWin effect ignores per-surface blur regions on normal windows and would blur the
// whole (tall, full-width) dock window, so the blur lives in this separate window instead.
// Protocol (one line per update, from dock/GlassLink.qml):
//   "<screen> <x> <width> <height> <bottom margin> <radius>"   (width 0 hides the window)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root
    property var geometry: ({})   // screen name -> { x, w, h, margin, radius }

    function apply(line) {
        const [name, x, w, h, margin, radius] = line.split(" ")
        if (!name || [x, w, h, margin, radius].some(v => isNaN(+v))) {
            console.warn("glass: ignoring malformed line:", line)
            return
        }
        root.geometry = Object.assign({}, root.geometry,
            { [name]: { x: +x, w: +w, h: +h, margin: +margin, radius: +radius } })
    }

    SocketServer {
        active: true
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/mac-dock-glass.sock"
        handler: Component {
            Socket { parser: SplitParser { onRead: line => root.apply(line) } }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            readonly property var g: root.geometry[modelData.name]
            screen: modelData
            visible: !!g && g.w > 0
            anchors { bottom: true; left: true }
            margins { left: g?.x ?? 0; bottom: g?.margin ?? 0 }
            implicitWidth: Math.max(1, g?.w ?? 1)
            implicitHeight: Math.max(1, g?.h ?? 1)
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            // Scope "dock" makes KWin treat it as a Dock: Glass then blurs exactly the requested
            // region below, rounded with its DockCornerRadius.
            WlrLayershell.namespace: "dock"
            color: "transparent"
            mask: Region {}
            BackgroundEffect.blurRegion: Region { item: fill; radius: g?.radius ?? 0 }
            Item { id: fill; anchors.fill: parent }
        }
    }
}
