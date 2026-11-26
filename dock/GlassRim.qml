import QtQuick

// Glass edge drawn over the blurred bar: bright top rim fading down, faint bottom reflection,
// soft inner glow and a light sheen. `strength` scales every alpha (0 = invisible).
Canvas {
    id: rim
    property real radius: 0
    property real strength: 1

    antialiasing: true
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onStrengthChanged: requestPaint()

    onPaint: {
        const c = getContext("2d")
        const w = width, h = height, r = radius
        const white = a => Qt.rgba(1, 1, 1, Math.min(1, a * strength))
        const gradient = stops => {
            const g = c.createLinearGradient(0, 0, 0, h)
            for (const [at, alpha] of stops) g.addColorStop(at, white(alpha))
            return g
        }
        // Explicit arcs: Canvas.roundedRect ignored large radii here.
        const roundedPath = (inset, rr) => {
            const l = inset, t = inset, rt = w - inset, b = h - inset
            c.beginPath()
            c.moveTo(l + rr, t)
            c.arcTo(rt, t, rt, b, rr)
            c.arcTo(rt, b, l, b, rr)
            c.arcTo(l, b, l, t, rr)
            c.arcTo(l, t, rt, t, rr)
            c.closePath()
        }

        c.reset()
        roundedPath(0, r)
        c.fillStyle = gradient([[0, 0.06], [0.45, 0], [1, 0.03]])
        c.fill()

        c.lineWidth = 1
        roundedPath(0.5, r - 0.5)
        c.strokeStyle = gradient([[0, 0.40], [0.35, 0.12], [0.8, 0.06], [1, 0.20]])
        c.stroke()

        roundedPath(1.5, r - 1.5)
        c.strokeStyle = gradient([[0, 0.12], [0.5, 0.04], [1, 0.06]])
        c.stroke()
    }
}
