// Draws the app icon: a bold cream serif "V" centered on deep navy.
//
// Run from the project folder:
//   swift Scripts/make_app_icon.swift
// It writes Versed/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png.
// The letter uses Apple's New York serif, the same typeface the app uses for verses.

import AppKit
import CoreText

let output = "Versed/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let size: CGFloat = 1024
let navy = color(0x1B2A4A)
let cream = color(0xF3EAD8)

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

// No transparency: the App Store rejects icons with an alpha channel.
let context = CGContext(
    data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
context.setFillColor(navy)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

let fontSize: CGFloat = 700
let systemFont = NSFont.systemFont(ofSize: fontSize, weight: .black)
let serifFont = NSFont(descriptor: systemFont.fontDescriptor.withDesign(.serif)!, size: fontSize)!
let letter = CTLineCreateWithAttributedString(NSAttributedString(string: "V", attributes: [
    .font: serifFont,
    .foregroundColor: cream,
]))

// Center the letter's actual ink, not its text box, so it sits visually in the middle.
let ink = CTLineGetImageBounds(letter, context)
context.textPosition = CGPoint(x: (size - ink.width) / 2 - ink.minX, y: (size - ink.height) / 2 - ink.minY)
CTLineDraw(letter, context)

let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
