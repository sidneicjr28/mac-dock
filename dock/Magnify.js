.pragma library

// Dock geometry with Gaussian magnification. Pure functions: no QML state.
// "x"/"width" here are along the dock's screen edge (vertical for a left/right dock).
//
// Sizes come from the cursor's distance to each slot's *rest* centre (unmagnified layout),
// so magnification never feeds back into itself.

// order: item indices in display order; restWidth(i): unmagnified width of item i;
// magnifies(i): whether item i grows; p: { width, spacing, pad, extra, sigma, mouseX, amount }.
function layout(order, restWidth, magnifies, p) {
    const n = order.length
    const gap = k => (k < n - 1 ? p.spacing : 0)

    let rest = 0
    const restCentre = []
    for (let k = 0; k < n; k++) {
        restCentre.push(rest + restWidth(order[k]) / 2)
        rest += restWidth(order[k]) + gap(k)
    }

    const mx = p.mouseX - (p.width - rest) / 2
    const sizes = [], xs = []
    let total = 0
    for (let k = 0; k < n; k++) {
        const i = order[k]
        let s = restWidth(i)
        if (magnifies(i)) {
            const d = mx - restCentre[k]
            s += p.extra * p.amount * Math.exp(-d * d / (2 * p.sigma * p.sigma))
        }
        sizes[i] = s
        total += s + gap(k)
    }

    let x = (p.width - total) / 2
    for (let k = 0; k < n; k++) {
        const i = order[k]
        xs[i] = x
        x += sizes[i] + p.spacing
    }
    return { xs, sizes, left: (p.width - total) / 2 - p.pad, width: total + p.pad * 2 }
}

// Display order while item `from` is being dragged to slot `to`.
function dragOrder(count, from, to) {
    const order = Array.from({ length: count }, (_, i) => i)
    if (from >= 0) { order.splice(from, 1); order.splice(to, 0, from) }
    return order
}

// Index of the item whose slot (including half the spacing on each side) contains x, else -1.
function hit(geo, count, x, spacing) {
    for (let i = 0; i < count; i++) {
        if (x >= geo.xs[i] - spacing / 2 && x <= geo.xs[i] + geo.sizes[i] + spacing / 2) return i
    }
    return -1
}

// Slot a dragged item should drop into: how many other pinned items lie left of x.
function dropSlot(geo, pinnedCount, from, x) {
    let slot = 0
    for (let i = 0; i < pinnedCount; i++)
        if (i !== from && geo.xs[i] + geo.sizes[i] / 2 < x) slot++
    return slot
}

// Uniform scale so the dock fits its screen edge (`edgeLength` long) and suits the resolution.
function scaleFor(screenW, screenH, edgeLength, needLength, edgeGap, autoScale) {
    const byResolution = autoScale
        ? Math.max(0.55, Math.min(1.5, Math.min(screenW / 1920, screenH / 1080))) : 1
    const toFit = needLength > 0 ? (edgeLength - 2 * edgeGap) / needLength : 1
    return Math.min(byResolution, toFit)
}
