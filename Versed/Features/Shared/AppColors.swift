import SwiftUI

// Versed's look in one place: "Quiet". Simple and classy, with just enough depth to feel modern.
// Navy ink on warm paper with soft white cards in light mode; cream on deep navy in dark mode.
// Every color is in the asset catalog with a light and a dark version.

extension ShapeStyle where Self == Color {
    /// Gray for less important text. Tuned to stay easy to read on both the page and the cards.
    static var secondaryText: Color { Color("SecondaryText") }

    /// The page behind everything: warm paper in light mode, deep navy in dark mode.
    static var appBackground: Color { Color("AppBackground") }

    /// Cards, pills, and the tab bar: soft white in light mode, lighter navy in dark mode.
    static var cardBackground: Color { Color("CardBackground") }

    /// Versed's navy ink (cream in dark mode), used for nearly all text and icons.
    static var brand: Color { Color("AccentColor") }

    /// A thin, quiet line around cards and between rows.
    static var hairline: Color { Color("Hairline") }

    /// The faint shadow under anything raised off the page.
    static var cardShadow: Color { Color("CardShadow") }
}

/// The three typefaces. All are free under the SIL Open Font License; the licenses are in Resources/Fonts.
/// Each one grows with the iPhone's text size through `relativeTo`.
///
/// Buttons, labels, and lists use the iPhone's own font, so they aren't listed here.
extension Font {
    /// PostScript names of the bundled fonts, as `UIFont` and `Font.custom` want them.
    enum Bundled {
        static let title = "SourceSerif4Display-Regular"
        static let number = "SourceSerif4Display-Light"
        static let verse = "EBGaramond-Regular"
        static let all = [title, number, verse]
    }

    /// Book names and screen titles.
    static func versedTitle(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(Bundled.title, size: size, relativeTo: style)
    }

    /// Chapter numbers. Its figures all sit at one even height.
    static func versedNumber(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(Bundled.number, size: size, relativeTo: style)
    }

    /// The scripture text itself.
    static func versedVerse(size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(Bundled.verse, size: size, relativeTo: style)
    }
}

extension View {
    /// Raises a view off the page: a soft white shape, a thin outline, and a faint shadow.
    /// The shadow sits on the shape alone, so text on top stays perfectly sharp.
    func raised<S: InsettableShape>(in shape: S) -> some View {
        background {
            shape
                .fill(Color.cardBackground)
                .shadow(color: .cardShadow, radius: 9, y: 6)
        }
        .overlay(shape.strokeBorder(Color.hairline))
    }

    /// A small raised pill, like the week picker at the top of the feed.
    func pillBackground() -> some View {
        raised(in: Capsule())
    }

    /// The shared look for lists and forms: the app's page color behind white cards.
    /// Pair it with `.listRowBackground(Color.cardBackground)` on each section.
    func versedListStyle() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.appBackground)
    }
}

/// A small, spaced-out, all-caps label above a group of rows, such as "CONTINUE READING".
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        SmallCapsLabel(title)
    }
}

/// A small, spaced-out, all-caps label, like "JEREMIAH 31:2" under a verse or "CHAPTER" above a number.
struct SmallCapsLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .tracking(1.7)
            .textCase(.uppercase)
            .foregroundStyle(.secondaryText)
    }
}

/// A thin line with a small diamond in the middle. Decoration only: VoiceOver skips it.
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
            .frame(width: 30, height: 1)
            .foregroundStyle(Color.brand.opacity(0.35))
    }
}

/// The small faint diamond from `Ornament`, on its own. Decoration only: VoiceOver skips it.
struct OrnamentDiamond: View {
    var body: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: 6))
            .foregroundStyle(Color.brand.opacity(0.45))
            .accessibilityHidden(true)
    }
}

/// The main button: a solid navy pill with cream text (cream with navy text in dark mode).
/// It's as wide as its label; add `.frame(maxWidth: .infinity)` to the label to fill the row.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color("ProminentButtonLabel"))
            .padding(.vertical, 15)
            .padding(.horizontal, 28)
            .background(Color("ProminentButton"), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// A quieter button: a small raised pill with navy text.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.brand)
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
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
