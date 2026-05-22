import QtQuick

/**
 * Schematic attitude indicator — HUD / FPV style.
 * Transparent background, line-only drawing (no fills).
 *
 * roll  — bank angle in degrees (+right wing down)
 * pitch — pitch angle in degrees (+nose up)
 */
Canvas {
    id: root

    property real roll:  0.0
    property real pitch: 0.0

    width:  260
    height: 260

    renderStrategy: Canvas.Threaded
    renderTarget:   Canvas.FramebufferObject

    onRollChanged:  requestPaint()
    onPitchChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)   // fully transparent

        var cx      = width  / 2
        var cy      = height / 2
        var r       = Math.min(cx, cy) - 2
        var pxPerDeg = r / 45.0

        // ── Everything that rotates with roll + shifts with pitch ─────────────
        ctx.save()
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
        ctx.clip()

        ctx.translate(cx, cy)
        ctx.rotate(roll * Math.PI / 180)

        var pOff = pitch * pxPerDeg   // positive pitch → horizon moves down

        // Horizon line (full width, broken gap in center so fixed marks show)
        ctx.strokeStyle = "white"
        ctx.lineWidth   = 1.5
        var gapHalf = r * 0.10          // small gap around center
        ctx.beginPath()
        ctx.moveTo(-r, pOff)
        ctx.lineTo(-gapHalf, pOff)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(gapHalf, pOff)
        ctx.lineTo(r, pOff)
        ctx.stroke()

        // Pitch ladder — short ticks left and right of center
        ctx.font = "9px monospace"
        for (var deg = -80; deg <= 80; deg += 10) {
            if (deg === 0) continue
            var ly  = pOff - deg * pxPerDeg
            var hw  = (Math.abs(deg) % 20 === 0) ? r * 0.28 : r * 0.15
            ctx.strokeStyle = "white"
            ctx.lineWidth   = 1
            // Left side tick
            ctx.beginPath()
            ctx.moveTo(-hw, ly)
            ctx.lineTo(-r * 0.06, ly)
            ctx.stroke()
            // Right side tick
            ctx.beginPath()
            ctx.moveTo(r * 0.06, ly)
            ctx.lineTo(hw, ly)
            ctx.stroke()
            // Labels on every 20°
            if (Math.abs(deg) % 20 === 0) {
                ctx.fillStyle  = "white"
                ctx.textAlign  = "right"
                ctx.fillText(Math.abs(deg), -hw - 3, ly + 4)
                ctx.textAlign  = "left"
                ctx.fillText(Math.abs(deg),  hw + 3, ly + 4)
            }
        }

        ctx.restore()   // end roll/pitch transform + clip

        // ── Fixed elements (do not rotate) ───────────────────────────────────

        // Center reference tick at top (shows 0° bank)
        ctx.strokeStyle = "rgba(255,255,255,0.6)"
        ctx.lineWidth = 2
        ctx.beginPath()
        ctx.moveTo(cx,      cy - r)
        ctx.lineTo(cx,      cy - r + 10)
        ctx.stroke()

        // Roll indicator triangle (rotates with roll, at top of circle)
        ctx.save()
        ctx.translate(cx, cy)
        ctx.rotate(roll * Math.PI / 180)
        ctx.strokeStyle = "white"
        ctx.fillStyle   = "white"
        ctx.lineWidth   = 1
        ctx.beginPath()
        ctx.moveTo( 0,  -(r - 2))
        ctx.lineTo(-5,  -(r - 13))
        ctx.lineTo( 5,  -(r - 13))
        ctx.closePath()
        ctx.fill()
        ctx.restore()

        // Fixed wing reference marks (horizontal dashes, left and right)
        ctx.strokeStyle = "white"
        ctx.lineWidth   = 2
        ctx.lineCap     = "square"
        // Left bar
        ctx.beginPath()
        ctx.moveTo(cx - r * 0.55, cy)
        ctx.lineTo(cx - r * 0.20, cy)
        ctx.stroke()
        // Left bar down-tick
        ctx.beginPath()
        ctx.moveTo(cx - r * 0.20, cy)
        ctx.lineTo(cx - r * 0.20, cy + r * 0.10)
        ctx.stroke()
        // Right bar
        ctx.beginPath()
        ctx.moveTo(cx + r * 0.20, cy)
        ctx.lineTo(cx + r * 0.55, cy)
        ctx.stroke()
        // Right bar down-tick
        ctx.beginPath()
        ctx.moveTo(cx + r * 0.20, cy)
        ctx.lineTo(cx + r * 0.20, cy + r * 0.10)
        ctx.stroke()

        // Center dot
        ctx.fillStyle = "white"
        ctx.beginPath()
        ctx.arc(cx, cy, 2.5, 0, 2 * Math.PI)
        ctx.fill()

        // Outer ring (subtle)
        ctx.strokeStyle = "rgba(255,255,255,0.25)"
        ctx.lineWidth   = 1.5
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
        ctx.stroke()
    }
}
