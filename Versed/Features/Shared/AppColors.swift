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

/// A small, spaced-out, all-caps label, like "JEREMIAH 31:2" under a verse or "SCRIPTURES" above a card.
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
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A thin line with a small diamond in the middle. Decoration only: VoiceOver skips it.
struct Ornament: View {
    var body: some View {
        HStack(spacing: 10) {
            line
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(Color.brand.opacity(0.45))
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

/// A soft white card holding a stack of rows. Separate the rows with `CardDivider`.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(shape)
        .raised(in: shape)
    }
}

/// A small label with a card under it, and an optional quiet note below the card.
struct CardSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SmallCapsLabel(title)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            Card { content }
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondaryText)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// The thin line between two rows in a card.
struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1)
            .padding(.leading, 16)
            .accessibilityHidden(true)
    }
}

/// One row in a card: a title, an optional detail on the right, and a small arrow.
/// VoiceOver and UI tests read the title as its label and the detail as its value.
struct CardRowLabel: View {
    let title: String
    var detail: String? = nil
    /// The small icon at the end of the row, or `nil` for a row that doesn't go anywhere.
    var symbol: String? = "chevron.forward"

    /// The arrow for rows that leave the app.
    static let externalLinkSymbol = "arrow.up.right"

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Side by side, or stacked at the largest text sizes so long words never break in the middle.
    private var layout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    var body: some View {
        HStack(spacing: 10) {
            layout {
                Text(title)
                    .foregroundStyle(.brand)
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: 0)
                }
                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if typeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            if let symbol {
                CardRowArrow(symbol: symbol)
            }
        }
        .multilineTextAlignment(.leading)
        .cardRowPadding()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail ?? "")
    }
}

/// The small arrow at the end of a card row.
struct CardRowArrow: View {
    var symbol = "chevron.forward"

    var body: some View {
        Image(systemName: symbol)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondaryText)
            .accessibilityHidden(true)
    }
}

extension View {
    /// The spacing inside a card row, tall enough to tap easily.
    func cardRowPadding() -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
    }

    /// The shared page behind a screen of cards. It scrolls, and leaves even margins.
    func versedPage() -> some View {
        padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
    }
}

/// A tappable card row: it dims while pressed.
struct CardRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.hairline : .clear)
    }
}

extension ButtonStyle where Self == CardRowButtonStyle {
    static var cardRow: CardRowButtonStyle { CardRowButtonStyle() }
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

/// The quietest button: a flat, faint navy pill, for tappable things that sit in the page's text.
/// It deepens while pressed. Set the font where it's used.
struct TintedPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.brand)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .frame(minWidth: 44, minHeight: 44)
            .background(Color.brand.opacity(configuration.isPressed ? 0.16 : 0.07), in: Capsule())
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == TintedPillButtonStyle {
    static var tintedPill: TintedPillButtonStyle { TintedPillButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
