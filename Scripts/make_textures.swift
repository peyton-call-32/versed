// Draws the seamless paper grain the app's pages are printed on.
// Each pixel is a touch of black or white, so one tile works on both the light and the dark colors.
//
// Run from the project folder:
//   swift Scripts/make_textures.swift
// It writes PaperGrain into Versed/Resources/Assets.xcassets.
// A fixed seed means every run draws exactly the same tiles.

import AppKit

/// A small repeatable random number generator.
struct Random {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) % 1_000_000) / 1_000_000
    }
    /// Between -1 and 1.
    mutating func signed() -> Double { next() * 2 - 1 }
}

let size = 512

/// Softens a tile, wrapping around its edges so the repeat never shows.
func blurred(_ values: [Double], passes: Int = 1) -> [Double] {
    var current = values
    for _ in 0..<passes {
        var next = current
        for y in 0..<size {
            for x in 0..<size {
                var total = 0.0
                for dy in -1...1 {
                    for dx in -1...1 {
                        total += current[((y + dy + size) % size) * size + (x + dx + size) % size]
                    }
                }
                next[y * size + x] = total / 9
            }
        }
        current = next
    }
    return current
}

/// Fine soft speckle with a few long, faint fibers, like uncoated book paper.
func paperGrain() -> [Double] {
    var random = Random(state: 1830)
    var fine = (0..<size * size).map { _ in random.signed() }
    fine = blurred(fine)
    var fibers = [Double](repeating: 0, count: size * size)
    for _ in 0..<900 {
        var x = random.next() * Double(size)
        var y = random.next() * Double(size)
        var angle = random.next() * .pi * 2
        let tone = random.signed() > 0 ? 1.0 : -1.0
        for _ in 0..<Int(14 + random.next() * 34) {
            fibers[(Int(y) % size) * size + Int(x) % size] += tone * 0.55
            angle += random.signed() * 0.28
            x = (x + cos(angle) + Double(size)).truncatingRemainder(dividingBy: Double(size))
            y = (y + sin(angle) + Double(size)).truncatingRemainder(dividingBy: Double(size))
        }
    }
    return zip(fine, fibers).map { $0 * 2.6 + $1 }
}


/// Saves a tile as a 3x image, so it stays fine and sharp on an iPhone's screen.
func write(_ values: [Double], strength: Double, name: String) throws {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bitmapFormat: [], bytesPerRow: size * 4, bitsPerPixel: 32
    )!
    let pixels = rep.bitmapData!
    for index in 0..<size * size {
        let value = values[index]
        let alpha = min(abs(value) * strength, 1)
        // Stored premultiplied: white pixels carry their alpha in the color, black ones don't.
        let level = value > 0 ? UInt8(alpha * 255) : 0
        pixels[index * 4] = level
        pixels[index * 4 + 1] = level
        pixels[index * 4 + 2] = level
        pixels[index * 4 + 3] = UInt8(alpha * 255)
    }
    let folder = URL(fileURLWithPath: "Versed/Resources/Assets.xcassets/\(name).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try rep.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("\(name).png"))
    let contents = """
    {
      "images" : [
        { "filename" : "\(name).png", "idiom" : "universal", "scale" : "3x" }
      ],
      "info" : { "author" : "xcode", "version" : 1 }
    }

    """
    try contents.write(to: folder.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}

try write(paperGrain(), strength: 0.05, name: "PaperGrain")
