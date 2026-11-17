import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders Driftstats' layered tvOS app icon and Top Shelf images: a load gauge, per-core bars and a network pulse.
// Usage (from repo root):
//   swift scripts/generate-icons.swift "TVDash/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets"
//
// Layers, back to front: Back (background and grid), Middle (core bars), Front (gauge track and ticks),
// Text (gauge value arc, needle and pulse). The folder names come from the asset catalog.

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func gradient(_ colors: [CGColor], _ locations: [CGFloat]? = nil) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locations)!
}

func render(_ w: Int, _ h: Int, opaque: Bool, _ draw: (CGContext, CGFloat, CGFloat) -> Void) -> CGImage {
    let ctx = CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast).rawValue)!
    ctx.setShouldAntialias(true)
    draw(ctx, CGFloat(w), CGFloat(h))
    return ctx.makeImage()!
}

func save(_ image: CGImage, _ relative: String) {
    let url = root.appendingPathComponent(relative)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "failed to write \(relative)")
}

/// Where the artwork sits inside an image: the gauge on the left, bars on the right.
struct Layout {
    let rect: CGRect

    var unit: CGFloat { rect.height / 240 }
    var center: CGPoint { CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.47) }
    var radius: CGFloat { rect.height * 0.29 }
    var ring: CGFloat { rect.height * 0.065 }
}

// The gauge sweeps 270°, clockwise from bottom-left to bottom-right.
let startAngle = CGFloat.pi * 1.25
let sweep = CGFloat.pi * 1.5
let value: CGFloat = 0.72

func angle(_ fraction: CGFloat) -> CGFloat { startAngle - sweep * fraction }

// MARK: Back

func background(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    ctx.drawLinearGradient(
        gradient([color(0x1B2A5E), color(0x0A0F24)]), start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func glowAndGrid(_ ctx: CGContext, _ layout: Layout) {
    let r = layout.rect
    ctx.drawRadialGradient(
        gradient([color(0x3A5BFF, 0.35), color(0x3A5BFF, 0)]), startCenter: layout.center, startRadius: 0,
        endCenter: layout.center, endRadius: layout.radius * 2.2, options: [])
    ctx.setStrokeColor(color(0xFFFFFF, 0.06))
    ctx.setLineWidth(1.2 * layout.unit)
    for y in stride(from: 0.2, through: 0.8, by: 0.12) {
        ctx.move(to: CGPoint(x: r.minX + r.width * 0.06, y: r.minY + r.height * y))
        ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.94, y: r.minY + r.height * y))
    }
    ctx.strokePath()
}

// MARK: Middle – one bar per core

let bars: [CGFloat] = [0.34, 0.56, 0.40, 0.66, 0.48]

func coreBars(_ ctx: CGContext, _ layout: Layout) {
    let r = layout.rect
    let barWidth = r.height * 0.065
    let gap = r.height * 0.035
    let baseline = r.minY + r.height * 0.2
    let startX = r.minX + r.width * 0.62
    for (index, height) in bars.enumerated() {
        let bar = CGRect(
            x: startX + CGFloat(index) * (barWidth + gap), y: baseline, width: barWidth, height: r.height * height)
        let path = CGPath(
            roundedRect: bar, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 10 * layout.unit, color: color(0x0A84FF, 0.6))
        ctx.addPath(path)
        ctx.setFillColor(color(0x0A84FF))
        ctx.fillPath()
        ctx.restoreGState()
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(
            gradient([color(0x64D2FF), color(0x0A64FF)]), start: CGPoint(x: 0, y: bar.maxY),
            end: CGPoint(x: 0, y: bar.minY), options: [])
        ctx.restoreGState()
    }
}

// MARK: Front – gauge track and ticks

func gaugeTrack(_ ctx: CGContext, _ layout: Layout) {
    let c = layout.center
    ctx.setLineCap(.round)
    ctx.setLineWidth(layout.ring)
    ctx.setStrokeColor(color(0xFFFFFF, 0.14))
    ctx.addArc(center: c, radius: layout.radius, startAngle: angle(0), endAngle: angle(1), clockwise: true)
    ctx.strokePath()

    ctx.setLineWidth(2.4 * layout.unit)
    ctx.setStrokeColor(color(0xFFFFFF, 0.45))
    for step in 0...10 {
        let a = angle(CGFloat(step) / 10)
        let inner = layout.radius + layout.ring * 0.9
        let outer = inner + (step % 5 == 0 ? 11 : 6) * layout.unit
        ctx.move(to: CGPoint(x: c.x + cos(a) * inner, y: c.y + sin(a) * inner))
        ctx.addLine(to: CGPoint(x: c.x + cos(a) * outer, y: c.y + sin(a) * outer))
    }
    ctx.strokePath()
}

// MARK: Text – value arc, needle and network pulse

func gaugeValue(_ ctx: CGContext, _ layout: Layout) {
    let c = layout.center
    let r = layout.radius

    // Soft glow under the arc.
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 16 * layout.unit, color: color(0x30D158, 0.7))
    ctx.setLineCap(.round)
    ctx.setLineWidth(layout.ring)
    ctx.setStrokeColor(color(0x30D158, 0.9))
    ctx.addArc(center: c, radius: r, startAngle: angle(0), endAngle: angle(value), clockwise: true)
    ctx.strokePath()
    ctx.restoreGState()

    // Green → yellow → orange along the arc.
    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineWidth(layout.ring)
    ctx.addArc(center: c, radius: r, startAngle: angle(0), endAngle: angle(value), clockwise: true)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(
        gradient([color(0x30D158), color(0xFFD60A), color(0xFF9F0A)], [0, 0.6, 1]),
        start: CGPoint(x: c.x - r, y: c.y - r * 0.4), end: CGPoint(x: c.x + r, y: c.y + r * 0.6),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()

    // Needle tip.
    let tipAngle = angle(value)
    let tip = CGPoint(x: c.x + cos(tipAngle) * r, y: c.y + sin(tipAngle) * r)
    let dot = layout.ring * 0.75
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 10 * layout.unit, color: color(0xFFFFFF, 0.8))
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fillEllipse(in: CGRect(x: tip.x - dot, y: tip.y - dot, width: dot * 2, height: dot * 2))
    ctx.restoreGState()

    pulse(ctx, layout)
}

/// A heartbeat-style line through the gauge's centre: the network being measured.
func pulse(_ ctx: CGContext, _ layout: Layout) {
    let c = layout.center
    let s = layout.radius * 0.62
    let points: [(CGFloat, CGFloat)] = [
        (-1.0, 0), (-0.45, 0), (-0.25, 0.55), (0, -0.7), (0.22, 0.35), (0.38, 0), (1.0, 0),
    ]
    let path = CGMutablePath()
    for (index, point) in points.enumerated() {
        let p = CGPoint(x: c.x + point.0 * s, y: c.y - s * 0.05 + point.1 * s)
        index == 0 ? path.move(to: p) : path.addLine(to: p)
    }
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 8 * layout.unit, color: color(0x64D2FF, 0.9))
    ctx.addPath(path)
    ctx.setStrokeColor(color(0xFFFFFF))
    ctx.setLineWidth(5 * layout.unit)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    ctx.restoreGState()
}

// MARK: Layered app icons

let stacks: [(folder: String, base: (Int, Int), scales: [Int])] = [
    ("App Icon.imagestack", (400, 240), [1, 2]),
    ("App Icon - App Store.imagestack", (1280, 768), [1, 2]),
]

for stack in stacks {
    for scale in stack.scales {
        let (w, h) = (stack.base.0 * scale, stack.base.1 * scale)
        let layout = Layout(rect: CGRect(x: 0, y: 0, width: w, height: h))
        let suffix = scale == 1 ? "" : "@\(scale)x"

        save(
            render(w, h, opaque: true) { ctx, w, h in
                background(ctx, w, h)
                glowAndGrid(ctx, layout)
            }, "\(stack.folder)/Back.imagestacklayer/Content.imageset/back\(suffix).png")
        save(
            render(w, h, opaque: false) { ctx, _, _ in coreBars(ctx, layout) },
            "\(stack.folder)/Middle.imagestacklayer/Content.imageset/middle\(suffix).png")
        save(
            render(w, h, opaque: false) { ctx, _, _ in gaugeTrack(ctx, layout) },
            "\(stack.folder)/Front.imagestacklayer/Content.imageset/front\(suffix).png")
        save(
            render(w, h, opaque: false) { ctx, _, _ in gaugeValue(ctx, layout) },
            "\(stack.folder)/Text.imagestacklayer/Content.imageset/text\(suffix).png")
    }
}

// MARK: Top Shelf (flat images)

func text(_ ctx: CGContext, _ string: String, size: CGFloat, weight: CTFontUIFontType, alpha: CGFloat, at point: CGPoint) {
    let font = CTFontCreateUIFontForLanguage(weight, size, nil)!
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(0xFFFFFF, alpha),
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
    ctx.textPosition = point
    CTLineDraw(line, ctx)
}

func topShelf(_ w: Int, _ h: Int) -> CGImage {
    render(w, h, opaque: true) { ctx, w, h in
        background(ctx, w, h)
        let unit = h / 720
        // Artwork on the right, at icon proportions.
        let art = Layout(rect: CGRect(x: w - h * 1.75, y: 0, width: h * 5 / 3, height: h))
        glowAndGrid(ctx, art)
        coreBars(ctx, art)
        gaugeTrack(ctx, art)
        gaugeValue(ctx, art)

        text(ctx, "Driftstats", size: 150 * unit, weight: .emphasizedSystem, alpha: 1, at: CGPoint(x: 120 * unit, y: h * 0.48))
        text(
            ctx, "RAM · Storage · CPU · Network", size: 46 * unit, weight: .system, alpha: 0.7,
            at: CGPoint(x: 124 * unit, y: h * 0.48 - 90 * unit))
    }
}

for (folder, base) in [("Top Shelf Image.imageset", (1920, 720)), ("Top Shelf Image Wide.imageset", (2320, 720))] {
    for scale in [1, 2] {
        let name = folder.hasPrefix("Top Shelf Image Wide") ? "top-shelf-wide" : "top-shelf"
        save(topShelf(base.0 * scale, base.1 * scale), "\(folder)/\(name)\(scale == 1 ? "" : "@2x").png")
    }
}
print("ok")
