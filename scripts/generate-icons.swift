import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders TVDash's layered tvOS app icon and Top Shelf images.
// Usage (from repo root):
//   swift scripts/generate-icons.swift "TVDash/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets"

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let green = color(0x34C759)
// Chart shape in unit coordinates (y up), kept inside the icon's safe area.
let curve: [CGPoint] = [
    (0.12, 0.30), (0.22, 0.42), (0.31, 0.36), (0.42, 0.53), (0.52, 0.47),
    (0.62, 0.62), (0.71, 0.57), (0.80, 0.72), (0.88, 0.70),
].map { CGPoint(x: $0.0, y: $0.1) }

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

func background(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    let gradient = CGGradient(
        colorsSpace: space, colors: [color(0x22345C), color(0x0B1220)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func path(_ points: [CGPoint], in rect: CGRect) -> CGMutablePath {
    let p = CGMutablePath()
    for (i, pt) in points.enumerated() {
        let q = CGPoint(x: rect.minX + pt.x * rect.width, y: rect.minY + pt.y * rect.height)
        i == 0 ? p.move(to: q) : p.addLine(to: q)
    }
    return p
}

func gridAndArea(_ ctx: CGContext, _ rect: CGRect, lineWidth: CGFloat) {
    ctx.setStrokeColor(color(0xFFFFFF, 0.10))
    ctx.setLineWidth(lineWidth)
    for y in stride(from: 0.25, through: 0.85, by: 0.15) {
        ctx.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * y))
        ctx.addLine(to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * y))
    }
    ctx.strokePath()

    let area = path(curve, in: rect)
    area.addLine(to: CGPoint(x: rect.minX + rect.width * curve.last!.x, y: rect.minY + rect.height * 0.18))
    area.addLine(to: CGPoint(x: rect.minX + rect.width * curve.first!.x, y: rect.minY + rect.height * 0.18))
    area.closeSubpath()
    ctx.saveGState()
    ctx.addPath(area)
    ctx.clip()
    let fill = CGGradient(
        colorsSpace: space, colors: [color(0x34C759, 0.45), color(0x34C759, 0.0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        fill, start: CGPoint(x: 0, y: rect.minY + rect.height * 0.75),
        end: CGPoint(x: 0, y: rect.minY + rect.height * 0.18), options: [])
    ctx.restoreGState()
}

func line(_ ctx: CGContext, _ rect: CGRect, width: CGFloat) {
    ctx.setShadow(offset: .zero, blur: width * 1.5, color: color(0x34C759, 0.6))
    ctx.addPath(path(curve, in: rect))
    ctx.setStrokeColor(green)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    let end = CGPoint(x: rect.minX + rect.width * curve.last!.x, y: rect.minY + rect.height * curve.last!.y)
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fillEllipse(in: CGRect(x: end.x - width * 1.1, y: end.y - width * 1.1, width: width * 2.2, height: width * 2.2))
}

// MARK: Layered app icons

let stacks: [(folder: String, base: (Int, Int), scales: [Int])] = [
    ("App Icon.imagestack", (400, 240), [1, 2]),
    ("App Icon - App Store.imagestack", (1280, 768), [1, 2]),
]

for stack in stacks {
    for scale in stack.scales {
        let (w, h) = (stack.base.0 * scale, stack.base.1 * scale)
        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        let unit = CGFloat(h) / 240
        let suffix = scale == 1 ? "" : "@\(scale)x"

        save(render(w, h, opaque: true) { ctx, w, h in background(ctx, w, h) },
             "\(stack.folder)/Back.imagestacklayer/Content.imageset/back\(suffix).png")
        save(render(w, h, opaque: false) { ctx, _, _ in gridAndArea(ctx, rect, lineWidth: 1.5 * unit) },
             "\(stack.folder)/Middle.imagestacklayer/Content.imageset/middle\(suffix).png")
        save(render(w, h, opaque: false) { ctx, _, _ in line(ctx, rect, width: 9 * unit) },
             "\(stack.folder)/Front.imagestacklayer/Content.imageset/front\(suffix).png")
    }
}

// MARK: Top Shelf (flat images)

func topShelf(_ w: Int, _ h: Int) -> CGImage {
    render(w, h, opaque: true) { ctx, w, h in
        background(ctx, w, h)
        let unit = h / 720
        let chart = CGRect(x: w - h * 2.0, y: 0, width: h * 1.9, height: h)
        gridAndArea(ctx, chart, lineWidth: 2 * unit)
        line(ctx, chart, width: 12 * unit)

        let font = CTFontCreateUIFontForLanguage(.emphasizedSystem, 150 * unit, nil)!
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(0xFFFFFF),
        ]
        let text = CTLineCreateWithAttributedString(NSAttributedString(string: "TVDash", attributes: attributes))
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.textPosition = CGPoint(x: 120 * unit, y: h * 0.42)
        CTLineDraw(text, ctx)
    }
}

for (folder, base) in [("Top Shelf Image.imageset", (1920, 720)), ("Top Shelf Image Wide.imageset", (2320, 720))] {
    for scale in [1, 2] {
        save(topShelf(base.0 * scale, base.1 * scale),
             "\(folder)/\(folder.hasPrefix("Top Shelf Image Wide") ? "top-shelf-wide" : "top-shelf")\(scale == 1 ? "" : "@2x").png")
    }
}
print("ok")
