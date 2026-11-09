import UIKit
import XCTest
@testable import Versed

/// Apple's accessibility audit can't read text on a textured surface, so it runs with textures off
/// (see `TextureTile`). This covers what it can't: even at the texture's strongest pixel, in light
/// and dark mode, every kind of text must keep at least 4.5:1 contrast, the standard for small text.
final class TextureContrastTests: XCTestCase {
    private static let smallTextMinimum = 4.5

    func testTextStaysReadableOnPaper() throws {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let surface = try color("AppBackground", style)
            let extremes = try extremes(of: TextureTile.paper, strength: TextureTile.paperStrength, over: surface)
            for ink in ["AccentColor", "SecondaryText"] {
                try assertReadable(color(ink, style), on: extremes, "\(ink) on paper, style \(style.rawValue)")
            }
        }
    }


    private typealias RGB = (red: Double, green: Double, blue: Double)

    private func color(_ name: String, _ style: UIUserInterfaceStyle) throws -> RGB {
        let color = try XCTUnwrap(UIColor(named: name))
        var (red, green, blue, alpha) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue)
    }

    /// The lightest and darkest the surface gets once the texture is laid over it.
    private func extremes(of tile: String, strength: Double, over surface: RGB) throws -> [RGB] {
        let image = try XCTUnwrap(UIImage(named: tile)?.cgImage)
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var strongestWhite = 0.0, strongestBlack = 0.0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[index + 3]) / 255
            if pixels[index] > 0 {
                strongestWhite = max(strongestWhite, alpha)
            } else {
                strongestBlack = max(strongestBlack, alpha)
            }
        }
        func over(_ tint: Double, _ alpha: Double) -> RGB {
            let amount = alpha * strength
            return (
                surface.red * (1 - amount) + tint * amount,
                surface.green * (1 - amount) + tint * amount,
                surface.blue * (1 - amount) + tint * amount
            )
        }
        return [over(1, strongestWhite), over(0, strongestBlack)]
    }

    private func assertReadable(_ ink: RGB, on surfaces: [RGB], _ name: String) {
        for surface in surfaces {
            let ratio = contrast(ink, surface)
            XCTAssertGreaterThanOrEqual(ratio, Self.smallTextMinimum, "\(name) falls to \(ratio):1")
        }
    }

    private func contrast(_ first: RGB, _ second: RGB) -> Double {
        let (a, b) = (luminance(first), luminance(second))
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private func luminance(_ color: RGB) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(color.red) + 0.7152 * channel(color.green) + 0.0722 * channel(color.blue)
    }
}
