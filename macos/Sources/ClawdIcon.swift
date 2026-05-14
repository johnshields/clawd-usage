import AppKit

/**
 * Renders Claw'd silhouette with bottom-up fill indicating usage percentage.
 * Replicates plasmoid ClawdIcon.qml behaviour using Core Graphics.
 */
enum ClawdIcon {
    private static let silhouette: NSImage? = {
        guard let url = Bundle.main.url(forResource: "clawd-silhouette", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()

    private static let eyes: NSImage? = {
        guard let url = Bundle.main.url(forResource: "clawd-eyes", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()

    static func render(pct: Double, loadError: Bool, size: NSSize,
                       warningThreshold: Double = 0.75) -> NSImage {
        guard let sil = silhouette else { return NSImage(size: size) }

        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let context = NSGraphicsContext.current else { return image }
        let ctx = context.cgContext
        let rect = NSRect(origin: .zero, size: size)
        let frac = max(0, min(1, pct / 100))

        if loadError {
            drawMaskedFill(ctx: ctx, silhouette: sil, rect: rect,
                           fillRect: rect, color: Theme.danger)
        } else {
            // Grey unfilled base
            drawMaskedFill(ctx: ctx, silhouette: sil, rect: rect,
                           fillRect: rect, color: Theme.dimmed)

            if frac > 0 {
                // Coloured fill from bottom (CG origin = bottom-left)
                let fillH = size.height * frac
                let fillRect = NSRect(x: 0, y: 0, width: size.width, height: fillH)
                drawMaskedFill(ctx: ctx, silhouette: sil, rect: rect, fillRect: fillRect,
                               color: Theme.usageColor(frac: frac, threshold: warningThreshold))
            }
        }

        eyes?.draw(in: rect)
        return image
    }

    /**
     * Draws silhouette clipped to fillRect, then applies source-in composite
     * to colour only the silhouette pixels within that region.
     */
    private static func drawMaskedFill(ctx: CGContext, silhouette: NSImage,
                                       rect: NSRect, fillRect: NSRect, color: NSColor) {
        ctx.saveGState()
        ctx.clip(to: fillRect)
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)

        silhouette.draw(in: rect)

        ctx.setBlendMode(.sourceIn)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)

        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }
}
