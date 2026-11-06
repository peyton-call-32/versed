import SwiftUI

// Versed's look in one place: "Hardcover". Every screen is set like a page of a fine bound book:
// navy ink on warm paper (cream on deep navy in dark mode), one family of serif type, thin ruled
// lines instead of cards, and nearly square corners. Nothing floats, glows, or fades.
// Chapter openings and the Browse book covers are solid navy with cream type in both modes.
// Every color is in the asset catalog with a light and a dark version.

extension ShapeStyle where Self == Color {
    /// Gray for less important text. Tuned to stay easy to read on the page.
    static var secondaryText: Color { Color("SecondaryText") }

    /// The page behind everything: warm paper in light mode, deep navy in dark mode.
    static var appBackground: Color { Color("AppBackground") }

    /// Versed's navy ink (cream in dark mode), used for nearly all text and icons.
    static var brand: Color { Color("AccentColor") }

    /// A thin, quiet ruled line.
    static var hairline: Color { Color("Hairline") }

    /// The faint shadow under a book cover, the one thing in the app with real weight.
    static var cardShadow: Color { Color("CardShadow") }

    /// The navy of a book cover: chapter openings and Browse's covers, in light and dark mode.
    static var cover: Color { Color("Cover") }

    /// The cream type and lines printed on a cover.
    static var onCover: Color { Color("OnCover") }
}

/// The shapes and lengths every screen shares.
enum Hardcover {
    /// Corners are nearly square, like cut paper. Used by every button and filled shape.
    static let cornerRadius: CGFloat = 3
    /// The left and right margin of every page.
    static let margin: CGFloat = 24

    static var corner: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
}

/// The three font styles. All are free under the SIL Open Font License; the licenses are in Resources/Fonts.
/// Each one grows with the iPhone's text size through `relativeTo`.
extension Font {
    /// PostScript names of the bundled fonts, as `UIFont` and `Font.custom` want them.
    enum Bundled {
        static let title = "Cormorant-Medium"
        static let number = "Cormorant-Light"
        static let verse = "Newsreader-Regular"
        static let all = [title, number, verse]
    }

    /// Book names and screen titles.
    static func versedTitle(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(Bundled.title, size: size, relativeTo: style)
    }

    /// Chapter numbers. The bundled file is set so its figures all sit at one even height.
    static func versedNumber(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(Bundled.number, size: size, relativeTo: style)
    }

    /// The scripture text itself.
    static func versedVerse(size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(Bundled.verse, size: size, relativeTo: style)
    }

    /// A row in a list, and the words on a button.
    static let versedRow = versedVerse(size: 18, relativeTo: .body)
    /// Smaller words beside a row, and the words at the top of a reading page.
    static let versedDetail = versedVerse(size: 15, relativeTo: .subheadline)
    /// Footnotes and quiet explanations.
    static let versedNote = versedVerse(size: 14, relativeTo: .footnote)
}

/// A small, spaced-out, all-caps label, like "JEREMIAH 31:2" under a verse or "SCRIPTURES" above a list.
struct SmallCapsLabel: View {
    let text: String
    var color: Color = .secondaryText

    init(_ text: String, color: Color = .secondaryText) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.versedVerse(size: 13, relativeTo: .footnote))
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A thin line with a small diamond in the middle. Decoration only: VoiceOver skips it.
struct Ornament: View {
    var color: Color = .brand
    var lineLength: CGFloat = 30
    /// Set to false to pull the lines back into the diamond. Animating it to true draws them outward.
    var isDrawn = true

    var body: some View {
        HStack(spacing: 10) {
            line(growingFrom: .trailing)
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(color.opacity(0.6))
            line(growingFrom: .leading)
        }
        .accessibilityHidden(true)
    }

    private func line(growingFrom anchor: UnitPoint) -> some View {
        Rectangle()
            .frame(width: lineLength, height: 1)
            .foregroundStyle(color.opacity(0.45))
            .scaleEffect(x: isDrawn ? 1 : 0, anchor: anchor)
    }
}

/// One thin ruled line, a single pixel on any screen.
struct Rule: View {
    var color: Color = .hairline
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1 / displayScale)
            .accessibilityHidden(true)
    }
}

/// Two thin lines, like the frame stamped on a book's cover.
struct CoverFrame: View {
    var body: some View {
        ZStack {
            Rectangle().strokeBorder(Color.onCover.opacity(0.55))
            Rectangle().strokeBorder(Color.onCover.opacity(0.25)).padding(5)
        }
        .accessibilityHidden(true)
    }
}

/// A stack of rows set straight on the page, with a ruled line above and below.
/// Separate the rows with `LedgerRule`.
struct Ledger<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rule()
            content
            Rule()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small label with a ledger under it, and an optional quiet note below.
struct LedgerSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SmallCapsLabel(title)
                .accessibilityAddTraits(.isHeader)
            Ledger { content }
            if let footer {
                Text(footer)
                    .font(.versedNote)
                    .foregroundStyle(.secondaryText)
            }
        }
    }
}

/// The thin line between two rows.
struct LedgerRule: View {
    var body: some View { Rule() }
}

/// One row: a title, an optional detail on the right, and a small arrow.
/// VoiceOver and UI tests read the title as its label and the detail as its value.
struct LedgerRowLabel: View {
    let title: String
    var detail: String? = nil
    /// The small icon at the end of the row, or `nil` for a row that doesn't go anywhere.
    var symbol: String? = "chevron.forward"
    /// Dots from the title to the detail, like a book's table of contents.
    var hasLeader = false

    /// The arrow for rows that leave the app.
    static let externalLinkSymbol = "arrow.up.right"

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Side by side, or stacked at the largest text sizes so long words never break in the middle.
    private var layout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

    var body: some View {
        HStack(spacing: 10) {
            layout {
                Text(title)
                    .font(.versedRow)
                    .foregroundStyle(.brand)
                if !typeSize.isAccessibilitySize {
                    if hasLeader {
                        LeaderDots().alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                if let detail {
                    Text(detail)
                        .font(.versedDetail)
                        .foregroundStyle(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if typeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            if let symbol {
                LedgerRowArrow(symbol: symbol)
            }
        }
        .multilineTextAlignment(.leading)
        .ledgerRowPadding()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(detail ?? "")
    }
}

/// One choice in a list, marked with a check when it's the one picked.
struct ChoiceRow: View {
    let title: String
    var detail: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.versedRow)
                        .foregroundStyle(.brand)
                    if let detail {
                        Text(detail)
                            .font(.versedDetail)
                            .foregroundStyle(.secondaryText)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.brand)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .ledgerRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.ledgerRow)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A few short choices side by side, with the one picked as a solid navy block.
/// Stacked at the largest text sizes, so a label never breaks in the middle.
struct BlockPicker<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 4))
        layout {
            ForEach(options) { option in
                let isSelected = selection == option
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .font(.versedDetail)
                        .foregroundStyle(isSelected ? Color("ProminentButtonLabel") : .brand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isSelected ? Color("ProminentButton") : .clear, in: Hardcover.corner)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }
}

/// The dotted line that leads the eye across a table of contents.
private struct LeaderDots: View {
    var body: some View {
        Line()
            .stroke(Color.secondaryText.opacity(0.55), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [0.1, 5]))
            .frame(height: 1)
            .frame(minWidth: 12)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

/// The small arrow at the end of a row.
struct LedgerRowArrow: View {
    var symbol = "chevron.forward"

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.secondaryText)
            .accessibilityHidden(true)
    }
}

extension View {
    /// The spacing inside a row, tall enough to tap easily.
    func ledgerRowPadding() -> some View {
        padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
    }

    /// The shared margins of a screen's contents.
    func versedPage() -> some View {
        padding(.horizontal, Hardcover.margin)
            .padding(.top, 8)
            .padding(.bottom, 28)
    }

    /// The shared look of a scrolling screen: plain paper, with none of the blur and fade strips
    /// that newer iOS versions draw at the edges of a scrolling screen.
    func versedScreen() -> some View {
        background(Color.appBackground)
            .hidesScrollEdgeEffects()
    }

    @ViewBuilder
    func hidesScrollEdgeEffects() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectHidden(true, for: .all)
        } else {
            self
        }
    }

    /// Every sheet in the app is the same: full height, on plain paper.
    func versedSheet() -> some View {
        presentationDetents([.large])
            .presentationBackground(Color.appBackground)
            .presentationDragIndicator(.hidden)
    }

    /// Pressing gives slightly under the finger, then springs back. Stays still with Reduce Motion on.
    func pressEffect(_ isPressed: Bool, scale: CGFloat = 0.97) -> some View {
        modifier(PressEffect(isPressed: isPressed, scale: scale))
    }
}

private struct PressEffect: ViewModifier {
    let isPressed: Bool
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !reduceMotion ? scale : 1)
            .animation(.spring(duration: 0.28, bounce: 0.2), value: isPressed)
    }
}

/// A tappable row: the words dim while pressed.
struct LedgerRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1)
    }
}

/// The main button: a solid navy block with cream words (cream with navy words in dark mode).
/// It's as wide as its label; add `.frame(maxWidth: .infinity)` to the label to fill the row.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.versedRow)
            .foregroundStyle(Color("ProminentButtonLabel"))
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(Color("ProminentButton"), in: Hardcover.corner)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .pressEffect(configuration.isPressed)
    }
}

/// A quieter button: navy words in a thin outline.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.versedRow)
            .foregroundStyle(.brand)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .overlay(Hardcover.corner.strokeBorder(Color.brand.opacity(0.35)))
            .contentShape(Hardcover.corner)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .pressEffect(configuration.isPressed)
    }
}

/// Words alone, for the small actions at the edge of a screen. Keeps a comfortable tap size.
struct PlainWordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.versedDetail)
            .foregroundStyle(.brand)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.45 : 1)
    }
}

/// Underlined words, like a week's chapter sections. Keeps a comfortable tap size.
/// Set the font where it's used.
struct UnderlinedLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.brand)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.brand.opacity(0.4)).frame(height: 1)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.45 : 1)
    }
}

extension ButtonStyle where Self == LedgerRowButtonStyle {
    static var ledgerRow: LedgerRowButtonStyle { LedgerRowButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == PlainWordButtonStyle {
    static var plainWord: PlainWordButtonStyle { PlainWordButtonStyle() }
}

extension ButtonStyle where Self == UnderlinedLinkButtonStyle {
    static var underlinedLink: UnderlinedLinkButtonStyle { UnderlinedLinkButtonStyle() }
}
