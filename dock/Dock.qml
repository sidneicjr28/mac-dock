import Quickshell
import Quickshell.Wayland
import QtQuick
import "Magnify.js" as Magnify

// The dock on one screen: sizing, magnification, drag-to-reorder and pointer input.
// Data and actions come from the injected services; visuals are delegated to child components.
PanelWindow {
    id: dock
    required property var config     // Config.values
    required property var model      // DockModel
    required property var catalog    // AppCatalog
    required property var tracker    // WindowTracker
    signal openSettings()

    readonly property var items: model.items

    // ---- sizing: config values scaled per screen (resolution + fit-to-width) ----
    readonly property int edgeGap: 16
    readonly property int separatorRest: 13
    readonly property real sizeScale: {
        const seps = items.filter(it => it.sep).length
        const n = items.length
        const need = (n - seps) * config.iconSize + seps * separatorRest
            + Math.max(0, n - 1) * config.spacing + 2 * config.padding
        return Magnify.scaleFor(screen.width, screen.height, need, edgeGap, config.autoScale)
    }
    readonly property int iconSize: Math.max(16, Math.round(config.iconSize * sizeScale))
    readonly property int maxIconSize: Math.round(iconSize * Math.max(1, config.magnification))
    readonly property int spacing: Math.round(config.spacing * sizeScale)
    readonly property int pad: Math.round(config.padding * sizeScale)
    readonly property int separatorWidth: Math.max(7, Math.round(separatorRest * sizeScale))
    readonly property int margin: config.margin
    readonly property int barHeight: iconSize + pad * 2
    // Must equal Glass's DockCornerRadius (KwinGlassSync keeps them in step); clamped for tiny bars.
    readonly property int cornerRadius: Math.min(config.cornerRadius, Math.floor(barHeight / 2))

    anchors { bottom: true; left: true; right: true }
    implicitHeight: margin + barHeight + (maxIconSize - iconSize) + 44   // room for magnification + tooltip
    exclusiveZone: margin + barHeight
    color: "transparent"
    // Dock type (like the glass window) so effects such as the desktop slide paint both in order.
    WlrLayershell.namespace: "dock"
    WlrLayershell.layer: WlrLayer.Top
    // Only the bar (or the magnified zone while hovering) takes input; the rest is click-through.
    mask: Region { item: hitZone }

    // ---- drag state ----
    property int dragFrom: -1
    property int dragTo: -1
    property real dragX: 0
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
    readonly property bool hovering: input.containsMouse && input.mouseY > bar.y - (maxIconSize - iconSize)
    property real hoverAmount: hovering ? 1 : 0
    Behavior on hoverAmount { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    readonly property var geo: Magnify.layout(
        Magnify.dragOrder(items.length, dragFrom, dragTo),
        i => items[i].sep ? separatorWidth : iconSize,
        i => !items[i].sep,
        { width, spacing, pad, extra: maxIconSize - iconSize, sigma: iconSize * 1.3,
          mouseX: input.mouseX, amount: hoverAmount })

    function iconAt(x) {
        const i = Magnify.hit(geo, items.length, x, spacing)
        return i >= 0 && !items[i].sep ? i : -1
    }

    function onBar(p) {
        return p.x >= bar.x && p.x <= bar.x + bar.width && p.y >= bar.y && p.y <= bar.y + bar.height
    }

    function showMenu(index) {
        const actions = []
        const it = index >= 0 ? items[index] : null
        if (it) actions.push(it.pinned
            ? { text: "Unpin from Dock", run: () => model.unpin(it.id) }
            : { text: "Keep in Dock", run: () => model.pin(it.id) })
        actions.push({ text: "Dock Settings…", run: () => dock.openSettings() })
        const slot = index >= 0 ? slots.itemAt(index) : null
        menu.show(actions, slot ? slot.x + slot.width / 2 : input.mouseX, bar.y)
    }

    Item {
        id: hitZone
        x: bar.x
        width: bar.width
        anchors.bottom: parent.bottom
        height: dock.hovering || dock.dragging ? dock.height : dock.margin + dock.barHeight
    }

    GlassLink {
        message: `${dock.screen.name} ${bar.x} ${dock.config.blur ? bar.width : 0} `
            + `${dock.barHeight} ${dock.margin} ${dock.cornerRadius}`
    }

    Rectangle {
        id: bar
        x: Math.round(dock.geo.left)
        width: Math.round(dock.geo.width)
        height: dock.barHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: dock.margin
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
            item: dock.items[index] ?? ({ id: "", pinned: false, sep: true })
            catalog: dock.catalog
            tracker: dock.tracker
            dockModel: dock.model
            size: dock.geo.sizes[index] ?? dock.iconSize
            slotX: dock.geo.xs[index] ?? 0
            restSize: dock.iconSize
            bottomY: dock.height - dock.margin - dock.pad
            dragged: dock.dragFrom === index
            dragX: dock.dragX
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
            pressIndex = dock.iconAt(e.x)
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
            dock.dragX = e.x
            dock.dragRemoves = e.y < bar.y - 60
            dock.dragTo = Magnify.dropSlot(dock.geo, dock.model.pinnedCount, dock.dragFrom, e.x)
        }

        onReleased: e => {
            const sameIcon = pressIndex >= 0 && pressIndex === dock.iconAt(e.x)
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
        readonly property int index: dock.hovering && !dock.dragging && !menu.visible ? dock.iconAt(input.mouseX) : -1
        target: index >= 0 ? slots.itemAt(index) : null
    }

    DockMenu {
        id: menu
        anchor.window: dock
    }
}
