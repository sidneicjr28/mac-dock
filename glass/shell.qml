// Bar-sized blur window, run by GlassProcess under a renamed quickshell binary.
// The Glass KWin effect ignores per-surface blur regions on normal windows and would blur the
// whole (tall, full-width) dock window, so the blur lives in this separate window instead.
// Protocol (one line per update, from dock/GlassLink.qml):
//   "<screen> <edge> <along> <length> <thickness> <lift> <radius> <layer>"   (length 0 hides it)
// along: offset along the screen edge; lift: distance from it; layer: bottom | top (top when
// windows may overlap the dock, i.e. auto-hide; the dock is then on Overlay, above this window).
// Each dock has its own connection; when it closes (screen deselected, dock restarted) that
// screen's glass is hidden.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root
    property var geometry: ({})   // screen name -> { edge, along, len, cross, lift, radius }

    readonly property var edges: ["bottom", "top", "left", "right"]

    function set(name, g) {
        const next = Object.assign({}, root.geometry)
        if (g) next[name] = g
        else delete next[name]
        root.geometry = next
    }

    // Returns the screen name the line was for, or "" if malformed.
    function apply(line) {
        const [name, edge, ...rest] = line.split(" ")
        const layer = rest.pop()
        const nums = rest
        const [along, len, cross, lift, radius] = nums.map(Number)
        if (!name || !edges.includes(edge) || !["top", "bottom"].includes(layer)
                || nums.length !== 5 || nums.some(v => v === "" || isNaN(+v))) {
            console.warn("glass: ignoring malformed line:", line)
            return ""
        }
        set(name, { edge, vertical: edge === "left" || edge === "right", along, len, cross, lift, radius, layer })
        return name
    }

    SocketServer {
        active: true
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/mac-dock-glass.sock"
        handler: Component {
            Socket {
                property string screenName
                parser: SplitParser { onRead: line => { screenName = root.apply(line) || screenName } }
                onConnectedChanged: if (!connected && screenName) root.set(screenName, null)
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            readonly property var g: root.geometry[modelData.name]
            readonly property bool vertical: g?.vertical ?? false
            screen: modelData
            visible: !!g && g.len > 0
            anchors {
                bottom: g?.edge === "bottom"
                top: g?.edge === "top" || vertical
                left: g?.edge === "left" || !vertical
                right: g?.edge === "right"
            }
            margins {
                left: vertical ? (g?.edge === "left" ? g.lift : 0) : (g?.along ?? 0)
                top: vertical ? (g?.along ?? 0) : (g?.edge === "top" ? g.lift : 0)
                right: g?.edge === "right" ? g.lift : 0
                bottom: g?.edge === "bottom" ? g.lift : 0
            }
            implicitWidth: Math.max(1, (vertical ? g?.cross : g?.len) ?? 1)
            implicitHeight: Math.max(1, (vertical ? g?.len : g?.cross) ?? 1)
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: g?.layer === "top" ? WlrLayer.Top : WlrLayer.Bottom
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
