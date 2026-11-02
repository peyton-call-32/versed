import SwiftUI

// Versed's look in one place. The colors match the app icon: deep navy and cream.
// Light mode is navy ink on warm off-white paper with white cards.
// Dark mode flips it: cream on deep navy with slightly lighter navy cards.
// Every color is in the asset catalog with a light and a dark version.

extension ShapeStyle where Self == Color {
    /// Gray for less important text. Tuned to stay easy to read on both the page and the cards.
    static var secondaryText: Color { Color("SecondaryText") }

    /// The page behind everything: warm off-white in light mode, deep navy in dark mode.
    static var appBackground: Color { Color("AppBackground") }

    /// Cards and list rows that sit on the page: white in light mode, lighter navy in dark mode.
    static var cardBackground: Color { Color("CardBackground") }

    /// Versed's navy (cream in dark mode), used for tab icons, small labels, and links.
    /// Set directly on the app's screens so iOS's default blue never shows up.
    static var brand: Color { Color("AccentColor") }

    /// A thin, quiet line around pills and tiles.
    static var hairline: Color { Color("Hairline") }
}

extension View {
    /// The shared look for lists and forms: the app's page color behind white cards.
    /// Pair it with `.listRowBackground(Color.cardBackground)` on each section.
    func versedListStyle() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }

    /// A small rounded pill, like the week picker and streak badge at the top of the feed.
    /// No shadow: the accessibility check reads a soft shadow as a blurry, low-contrast edge.
    func pillBackground() -> some View {
        background(Color.cardBackground, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.hairline))
    }
}

/// A small, spaced-out, all-caps label above a group of rows, such as "CONTINUE READING".
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .tracking(1.5)
            .textCase(.uppercase)
            .foregroundStyle(.secondaryText)
    }
}

/// A small, spaced-out, all-caps label used inside the feed, like "JEREMIAH 31:2" under a verse
/// or "CHAPTER" above a chapter number. Same look as `SectionHeader`, but a touch larger.
struct SmallCapsLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .tracking(3)
            .textCase(.uppercase)
            .foregroundStyle(.secondaryText)
    }
}

/// A thin line with a small diamond in the middle, in faint navy (faint cream in dark mode).
/// Decoration only: VoiceOver skips it.
struct Ornament: View {
    var body: some View {
        HStack(spacing: 10) {
            line
            OrnamentDiamond()
            line
        }
        .accessibilityHidden(true)
    }

    private var line: some View {
        Rectangle()
            .frame(width: 32, height: 1)
            .foregroundStyle(Color.brand.opacity(0.35))
    }
}

/// The small faint diamond from `Ornament`, on its own. Also used between chapter sections
/// on the week card ("1–3 ◆ 33–34"). Decoration only: VoiceOver skips it.
struct OrnamentDiamond: View {
    var body: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: 6))
            .foregroundStyle(Color.brand.opacity(0.35))
            .accessibilityHidden(true)
    }
}

/// The main button: a full-width navy pill with cream text (cream with navy text in dark mode).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("ProminentButtonLabel"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(Color("ProminentButton"), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// A quieter button: a white pill with a thin outline.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .pillBackground()
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
