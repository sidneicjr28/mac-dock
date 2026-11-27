import Quickshell
import Quickshell.Wayland
import QtQuick
import "Magnify.js" as Magnify

// The dock on one screen: placement, sizing, magnification, auto-hide, drag-to-reorder and input.
// Data and actions come from the injected services; visuals are delegated to child components.
// Layout works in edge coordinates: "along" the screen edge and "lift" (distance from the edge);
// place() maps them to window coordinates for the configured edge.
PanelWindow {
    id: dock
    required property var config     // Config.values
    required property var model      // DockModel
    required property var catalog    // AppCatalog
    required property var tracker    // WindowTracker
    signal openSettings()

    readonly property var items: model.items

    // ---- placement ----
    readonly property string edge: ["bottom", "top", "left", "right"].includes(config.position)
        ? config.position : "bottom"
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real length: vertical ? height : width

    function place(along, lift, len, cross) {
        switch (edge) {
        case "top": return Qt.rect(along, lift, len, cross)
        case "left": return Qt.rect(lift, along, cross, len)
        case "right": return Qt.rect(width - lift - cross, along, cross, len)
        default: return Qt.rect(along, height - lift - cross, len, cross)
        }
    }
    function alongOf(x, y) { return vertical ? y : x }
    function liftOf(x, y) {
        switch (edge) {
        case "top": return y
        case "left": return x
        case "right": return width - x
        default: return height - y
        }
    }

    // ---- sizing: config values scaled per screen (resolution + fit-to-edge) ----
    readonly property int edgeGap: 16
    readonly property int separatorRest: 13
    readonly property real sizeScale: {
        const seps = items.filter(it => it.sep).length
        const n = items.length
        const need = (n - seps) * config.iconSize + seps * separatorRest
            + Math.max(0, n - 1) * config.spacing + 2 * config.padding
        return Magnify.scaleFor(screen.width, screen.height, vertical ? screen.height : screen.width,
            need, edgeGap, config.autoScale)
    }
    readonly property int iconSize: Math.max(16, Math.round(config.iconSize * sizeScale))
    readonly property int maxIconSize: Math.round(iconSize * Math.max(1, config.magnification))
    readonly property int extra: maxIconSize - iconSize
    readonly property int spacing: Math.round(config.spacing * sizeScale)
    readonly property int pad: Math.round(config.padding * sizeScale)
    readonly property int separatorWidth: Math.max(7, Math.round(separatorRest * sizeScale))
    readonly property int margin: config.margin
    readonly property int barHeight: iconSize + pad * 2
    // Must equal Glass's DockCornerRadius (KwinGlassSync keeps them in step); clamped for tiny bars.
    readonly property int cornerRadius: Math.min(config.cornerRadius, Math.floor(barHeight / 2))
    // Room past the bar for magnification and the tooltip (which sits beside a vertical dock).
    readonly property int thickness: margin + barHeight + extra + (vertical ? 240 : 44)

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitWidth: thickness
    implicitHeight: thickness
    // Auto-hide reserves no space. Via Ignore: changing exclusiveZone to 0 at runtime is not
    // applied (the old zone stays, leaving a gap under maximized windows).
    exclusiveZone: margin + barHeight
    exclusionMode: config.autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
    color: "transparent"
    // Dock type (like the glass window) so effects such as the desktop slide paint both in order.
    WlrLayershell.namespace: "dock"
    // With auto-hide, windows reach under the dock, so the glass moves up to Top (above them) and
    // the dock to Overlay while shown; once fully hidden it drops back below fullscreen windows.
    WlrLayershell.layer: config.autoHide && hideOffset < hiddenOffset ? WlrLayer.Overlay : WlrLayer.Top
    // Only the bar (or the magnified zone while hovering) takes input; the rest is click-through.
    mask: Region { item: hitZone }

    // ---- auto-hide: slide off the edge, come back when the pointer touches it ----
    readonly property bool keepShown: !config.autoHide || hovering || dragging || menu.visible
    property bool revealed: true
    onKeepShownChanged: {
        if (keepShown) { hideDelay.stop(); revealed = true }
        else hideDelay.restart()
    }
    Component.onCompleted: revealed = keepShown
    Timer { id: hideDelay; interval: 600; onTriggered: dock.revealed = dock.keepShown }

    readonly property real hiddenOffset: margin + barHeight + 4
    property real hideOffset: revealed ? 0 : hiddenOffset
    Behavior on hideOffset { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    readonly property real lift: margin - hideOffset   // bar's distance from the edge

    // ---- drag state ----
    property int dragFrom: -1
    property int dragTo: -1
    property real dragAlong: 0
    property bool dragRemoves: false
    property bool animateSlots: false
    readonly property bool dragging: dragFrom >= 0

    function finishDrag() {
        model.reorderVisible(dragFrom, dragTo, dragRemoves)
        animateSlots = false
        dragFrom = -1
        dragTo = -1
        dragRemoves = false
    }

    // ---- magnification ----
    readonly property real pointerAlong: alongOf(input.mouseX, input.mouseY)
    readonly property bool hovering: input.containsMouse
        && liftOf(input.mouseX, input.mouseY) < margin + barHeight + extra
    property real hoverAmount: hovering ? 1 : 0
    Behavior on hoverAmount { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    readonly property var geo: Magnify.layout(
        Magnify.dragOrder(items.length, dragFrom, dragTo),
        i => items[i].sep ? separatorWidth : iconSize,
        i => !items[i].sep,
        { width: length, spacing, pad, extra, sigma: iconSize * 1.3,
          mouseX: pointerAlong, amount: hoverAmount })

    readonly property int barAlong: Math.round(geo.left)
    readonly property int barLength: Math.round(geo.width)
    readonly property rect barRect: place(barAlong, lift, barLength, barHeight)

    function iconAt(along) {
        const i = Magnify.hit(geo, items.length, along, spacing)
        return i >= 0 && !items[i].sep ? i : -1
    }

    function onBar(p) {
        const r = barRect
        return p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height
    }

    function showMenu(index) {
        const actions = []
        const it = index >= 0 ? items[index] : null
        if (it) actions.push(it.pinned
            ? { text: "Unpin from Dock", run: () => model.unpin(it.id) }
            : { text: "Keep in Dock", run: () => model.pin(it.id) })
        actions.push({ text: "Dock Settings…", run: () => dock.openSettings() })
        const slot = index >= 0 ? slots.itemAt(index) : null
        const at = slot ? alongOf(slot.x + slot.width / 2, slot.y + slot.height / 2) : pointerAlong
        const p = place(at, lift + barHeight + 8, 0, 0)
        menu.show(actions, p.x, p.y, edge)
    }

    Item {
        id: hitZone
        // Hidden: a thin strip along the edge to bring the dock back.
        readonly property real depth: !dock.revealed ? 2
            : dock.hovering || dock.dragging ? dock.thickness : dock.margin + dock.barHeight
        readonly property rect r: dock.place(dock.barAlong, 0, dock.barLength, depth)
        x: r.x; y: r.y; width: r.width; height: r.height
    }

    GlassLink {
        // Clip the glass to the visible part of the bar while it slides off the edge.
        readonly property real cross: dock.barHeight + Math.min(0, dock.lift)
        message: `${dock.screen.name} ${dock.edge} ${dock.barAlong} `
            + `${dock.config.blur && cross > 0 ? dock.barLength : 0} ${Math.round(Math.max(1, cross))} `
            + `${Math.round(Math.max(0, dock.lift))} ${dock.cornerRadius} ${dock.config.autoHide ? "top" : "bottom"}`
    }

    Rectangle {
        id: bar
        x: dock.barRect.x
        y: dock.barRect.y
        width: dock.barRect.width
        height: dock.barRect.height
        radius: dock.cornerRadius
        color: {
            const c = Qt.color(dock.config.bgColor)
            return Qt.rgba(c.r, c.g, c.b, dock.config.bgOpacity)
        }

        GlassRim {
            anchors.fill: parent
            radius: dock.cornerRadius
            strength: dock.config.rimOpacity
        }
    }

    Repeater {
        id: slots
        model: dock.items.length
        DockItem {
            required property int index
            readonly property real len: dock.geo.sizes[index] ?? dock.iconSize
            readonly property rect r: dock.place(
                dragged ? dock.dragAlong - len / 2 : (dock.geo.xs[index] ?? 0),
                dock.lift + dock.pad + (dragged ? 12 : 0),
                len, isSeparator ? dock.iconSize : len)
            x: r.x; y: r.y; width: r.width; height: r.height
            item: dock.items[index] ?? ({ id: "", pinned: false, sep: true })
            edge: dock.edge
            catalog: dock.catalog
            tracker: dock.tracker
            dockModel: dock.model
            dragged: dock.dragFrom === index
            fadeOut: dock.dragRemoves
            animateSlots: dock.animateSlots
        }
    }

    MouseArea {
        id: input
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        property int pressIndex: -1
        property point pressPos

        onPressed: e => {
            pressIndex = dock.iconAt(dock.alongOf(e.x, e.y))
            pressPos = Qt.point(e.x, e.y)
        }

        onPositionChanged: e => {
            if (pressIndex < 0 || !(pressedButtons & Qt.LeftButton)) return
            if (!dock.dragging) {
                if (!dock.items[pressIndex].pinned) return
                if (Math.abs(e.x - pressPos.x) + Math.abs(e.y - pressPos.y) < 8) return
                dock.dragTo = pressIndex
                dock.dragFrom = pressIndex
                dock.animateSlots = true
            }
            const along = dock.alongOf(e.x, e.y)
            dock.dragAlong = along
            dock.dragRemoves = dock.liftOf(e.x, e.y) > dock.margin + dock.barHeight + 60
            dock.dragTo = Magnify.dropSlot(dock.geo, dock.model.pinnedCount, dock.dragFrom, along)
        }

        onReleased: e => {
            const sameIcon = pressIndex >= 0 && pressIndex === dock.iconAt(dock.alongOf(e.x, e.y))
            const release = Qt.point(e.x, e.y)
            if (dock.dragging) dock.finishDrag()
            else if (e.button === Qt.RightButton) {
                if (sameIcon) dock.showMenu(pressIndex)
                else if (dock.onBar(pressPos)) dock.showMenu(-1)
            }
            else if (sameIcon) slots.itemAt(pressIndex).trigger(e.button)
            else if (pressIndex < 0 && e.button === Qt.LeftButton && dock.onBar(pressPos) && dock.onBar(release))
                dock.openSettings()
            pressIndex = -1
        }
    }

    DockTooltip {
        readonly property int index: dock.hovering && !dock.dragging && !menu.visible
            ? dock.iconAt(dock.pointerAlong) : -1
        target: index >= 0 ? slots.itemAt(index) : null
        edge: dock.edge
    }

    DockMenu {
        id: menu
        anchor.window: dock
    }
}
