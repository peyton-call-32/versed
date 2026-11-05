#!/usr/bin/env swift
// Pulls evenly spaced frames out of a screen recording and lays them side by side in one image,
// so a transition can be checked frame by frame. No extra software needed.
//
//   swift Scripts/contact_sheet.swift recording.mov sheet.png <start-seconds> <end-seconds> <frame-count> [columns]
import AppKit
import AVFoundation

let args = CommandLine.arguments
guard args.count >= 6, let start = Double(args[3]), let end = Double(args[4]), let count = Int(args[5]) else {
    print("usage: contact_sheet.swift video output start end count [columns]"); exit(1)
}
let columns = args.count > 6 ? Int(args[6])! : count
let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
generator.maximumSize = CGSize(width: 330, height: 0)

var images: [(Double, CGImage)] = []
for index in 0..<count {
    let seconds = start + (end - start) * Double(index) / Double(max(count - 1, 1))
    if let image = try? generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: nil) {
        images.append((seconds, image))
    }
}
guard let first = images.first?.1 else { print("no frames"); exit(1) }
let gap = 8, label = 22
let rows = Int(ceil(Double(images.count) / Double(columns)))
let width = columns * (first.width + gap) + gap
let height = rows * (first.height + gap + label) + gap
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(white: 0.5, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()
for (index, (seconds, image)) in images.enumerated() {
    let column = index % columns, row = index / columns
    let x = gap + column * (first.width + gap)
    let y = height - (row + 1) * (first.height + gap + label)
    NSImage(cgImage: image, size: .zero).draw(in: NSRect(x: x, y: y, width: first.width, height: first.height))
    String(format: "%.3fs", seconds).draw(at: NSPoint(x: x, y: y + first.height + 2), withAttributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.white])
}
NSGraphicsContext.current = nil
try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
print("wrote \(images.count) frames to \(args[2]); video length \(CMTimeGetSeconds(asset.duration))s")
