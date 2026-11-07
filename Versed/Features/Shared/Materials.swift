import SwiftUI

// What the app's surfaces are made of. Depth comes from real bookbinding materials and from the
// shadows real objects would cast, never from gradients, glass, or glow. The tiles are drawn by
// Scripts/make_textures.swift.

/// A seamless texture laid over a color. Touches pass straight through, and being decorative, VoiceOver never sees it.
struct TextureTile: View {
    let name: String
    var strength: Double = 1

    static let paper = "PaperGrain"
    static let cloth = "BookCloth"
    /// How strongly the page's own grain is printed. `TextureContrastTests` checks it keeps text readable.
    static let paperStrength = 0.42
    /// Felt more than seen: the weave should never compete with the words on it.
    static let clothStrength = 0.72

    /// Apple's accessibility audit misreads any grain behind text as poor contrast, so its test
    /// turns textures off to check the colors, and `TextureContrastTests` covers the textures.
    private static let isHidden = ProcessInfo.processInfo.arguments.contains("-plain-surfaces")

    var body: some View {
        if !Self.isHidden {
            Image(decorative: name)
                .resizable(resizingMode: .tile)
                .opacity(strength)
                .allowsHitTesting(false)
        }
    }
}

/// The page behind everything: the app's paper color with a fine grain.
struct PaperSurface: View {
    var body: some View {
        Color.appBackground
            .overlay { TextureTile(name: TextureTile.paper, strength: TextureTile.paperStrength) }
            .ignoresSafeArea()
    }
}

/// Navy bookcloth, for covers, chapter openings, and the open plan.
struct ClothSurface: View {
    var body: some View {
        Color.cover
            .overlay { TextureTile(name: TextureTile.cloth, strength: TextureTile.clothStrength) }
    }
}

extension View {
    /// Type pressed into bookcloth: a sharp shadow above each letter and a catch of light below.
    func stampedIntoCloth() -> some View {
        shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: -0.5)
            .shadow(color: .white.opacity(0.09), radius: 0, x: 0, y: 0.5)
    }

    /// The tight shadow along the edge of a band of paper lying over the page. Kept short, so it
    /// reads as an edge rather than a fade. `rise` is which way it falls: up from the tab bar, down from the top.
    func paperEdgeShadow(rise: CGFloat) -> some View {
        shadow(color: .cardShadow.opacity(0.7), radius: 2.5, x: 0, y: rise)
    }

    /// The shadow of a real object resting on the page: tight where it touches, soft further out.
    func restingShadow(depth: CGFloat = 1) -> some View {
        shadow(color: .cardShadow, radius: 1.5 * depth, x: 0, y: 1 * depth)
            .shadow(color: .cardShadow, radius: 11 * depth, x: 0, y: 7 * depth)
    }
}
