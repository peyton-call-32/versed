import SwiftUI

/// The app's icons, drawn by hand so their fine line matches the serif type around them.
/// Each is drawn in a square from 0 to 1 and keeps the same thin line at any size.
enum Glyph {
    case chevronForward, chevronBack, chevronDown, chevronUp
    case arrowUp, arrowUpRight
    case check, plus, search
    case heart, ribbon, books, sliders

    fileprivate func outline(in rect: CGRect) -> Path {
        var pen = Pen(rect: rect)
        switch self {
        case .chevronForward: pen.line((0.34, 0.1), (0.68, 0.5), (0.34, 0.9))
        case .chevronBack: pen.line((0.66, 0.1), (0.32, 0.5), (0.66, 0.9))
        case .chevronDown: pen.line((0.1, 0.34), (0.5, 0.68), (0.9, 0.34))
        case .chevronUp: pen.line((0.1, 0.66), (0.5, 0.32), (0.9, 0.66))
        case .arrowUp:
            pen.line((0.5, 0.94), (0.5, 0.08))
            pen.line((0.2, 0.38), (0.5, 0.08), (0.8, 0.38))
        case .arrowUpRight:
            pen.line((0.16, 0.84), (0.84, 0.16))
            pen.line((0.32, 0.16), (0.84, 0.16), (0.84, 0.68))
        case .check: pen.line((0.1, 0.55), (0.38, 0.84), (0.92, 0.18))
        case .plus:
            pen.line((0.5, 0.1), (0.5, 0.9))
            pen.line((0.1, 0.5), (0.9, 0.5))
        case .search:
            pen.circle(center: (0.43, 0.43), radius: 0.33)
            pen.line((0.67, 0.67), (0.92, 0.92))
        case .heart: pen.heart()
        case .ribbon: pen.shape((0.25, 0.06), (0.75, 0.06), (0.75, 0.94), (0.5, 0.73), (0.25, 0.94))
        case .books:
            pen.shape((0.1, 0.14), (0.3, 0.14), (0.3, 0.9), (0.1, 0.9))
            pen.shape((0.36, 0.26), (0.54, 0.26), (0.54, 0.9), (0.36, 0.9))
            pen.shape((0.6, 0.3), (0.76, 0.25), (0.94, 0.85), (0.77, 0.9))
        case .sliders:
            pen.line((0.06, 0.32), (0.53, 0.32))
            pen.line((0.79, 0.32), (0.94, 0.32))
            pen.circle(center: (0.66, 0.32), radius: 0.13)
            pen.line((0.06, 0.7), (0.21, 0.7))
            pen.line((0.47, 0.7), (0.94, 0.7))
            pen.circle(center: (0.34, 0.7), radius: 0.13)
        }
        return pen.path
    }

    /// What fills in while selected. Most glyphs fill whole; the sliders fill only their knobs.
    fileprivate func filling(in rect: CGRect) -> Path {
        guard case .sliders = self else { return outline(in: rect) }
        var pen = Pen(rect: rect)
        pen.circle(center: (0.66, 0.32), radius: 0.13)
        pen.circle(center: (0.34, 0.7), radius: 0.13)
        return pen.path
    }

    /// Draws in the 0-to-1 square, whatever size the glyph ends up.
    private struct Pen {
        let rect: CGRect
        var path = Path()

        private func point(_ spot: (CGFloat, CGFloat)) -> CGPoint {
            CGPoint(x: rect.minX + spot.0 * rect.width, y: rect.minY + spot.1 * rect.height)
        }

        mutating func line(_ spots: (CGFloat, CGFloat)...) {
            path.addLines(spots.map(point))
        }

        mutating func shape(_ spots: (CGFloat, CGFloat)...) {
            path.addLines(spots.map(point))
            path.closeSubpath()
        }

        mutating func circle(center: (CGFloat, CGFloat), radius: CGFloat) {
            let middle = point(center)
            let size = radius * rect.width
            path.addEllipse(in: CGRect(x: middle.x - size, y: middle.y - size, width: size * 2, height: size * 2))
        }

        /// Slender, with a clean point at the foot and a soft cleft at the top.
        mutating func heart() {
            path.move(to: point((0.5, 0.92)))
            path.addCurve(to: point((0.05, 0.33)), control1: point((0.32, 0.77)), control2: point((0.05, 0.57)))
            path.addCurve(to: point((0.29, 0.09)), control1: point((0.05, 0.18)), control2: point((0.16, 0.09)))
            path.addCurve(to: point((0.5, 0.23)), control1: point((0.39, 0.09)), control2: point((0.46, 0.15)))
            path.addCurve(to: point((0.71, 0.09)), control1: point((0.54, 0.15)), control2: point((0.61, 0.09)))
            path.addCurve(to: point((0.95, 0.33)), control1: point((0.84, 0.09)), control2: point((0.95, 0.18)))
            path.addCurve(to: point((0.5, 0.92)), control1: point((0.95, 0.57)), control2: point((0.68, 0.77)))
            path.closeSubpath()
        }
    }
}

/// One hand-drawn icon. Set its color with `foregroundStyle`.
struct GlyphView: View {
    let glyph: Glyph
    var size: CGFloat = 14
    var lineWidth: CGFloat = 1.1
    /// How filled in it is, from 0 to 1. Animating it pours the ink in.
    var fill: CGFloat = 0

    init(_ glyph: Glyph, size: CGFloat = 14, lineWidth: CGFloat = 1.1, fill: CGFloat = 0) {
        self.glyph = glyph
        self.size = size
        self.lineWidth = lineWidth
        self.fill = fill
    }

    var body: some View {
        ZStack {
            GlyphShape(glyph: glyph, isFill: true)
                .opacity(fill)
                .scaleEffect(0.6 + 0.4 * fill)
            GlyphShape(glyph: glyph, isFill: false)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct GlyphShape: Shape {
    let glyph: Glyph
    let isFill: Bool

    func path(in rect: CGRect) -> Path {
        isFill ? glyph.filling(in: rect) : glyph.outline(in: rect)
    }
}

/// A printer's swelled rule: a line that thickens in the middle and tapers to nothing at each end.
struct SwelledRuleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let leading = CGPoint(x: rect.minX, y: rect.midY)
        let trailing = CGPoint(x: rect.maxX, y: rect.midY)
        path.move(to: leading)
        path.addCurve(
            to: trailing,
            control1: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.midY - rect.height * 0.67),
            control2: CGPoint(x: rect.maxX - rect.width * 0.38, y: rect.midY - rect.height * 0.67)
        )
        path.addCurve(
            to: leading,
            control1: CGPoint(x: rect.maxX - rect.width * 0.38, y: rect.midY + rect.height * 0.67),
            control2: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.midY + rect.height * 0.67)
        )
        path.closeSubpath()
        return path
    }
}
