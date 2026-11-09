import SwiftUI

// Versed's look in one place: "Hardcover". Every screen is set like a page of a fine bound book:
// navy ink on warm paper (cream on deep navy in dark mode), one family of serif type, and nearly
// square corners. Rows sit on the page like a table of contents, with a line only at the head of a
// section. Nothing glows. Only real objects cast a shadow (see Materials.swift).
// Chapter openings and the Library's book covers are smooth navy with cream type in both modes.
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

    /// The shadow of a real object on the page: a book, the ribbon, the open plan, the tab bar's band.
    static var cardShadow: Color { Color("CardShadow") }

    /// The navy of a book cover: chapter openings, the Library's covers, and Today's open plan, in light and dark mode.
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
    /// The open space between two sections of a page.
    static let sectionSpacing: CGFloat = 36

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

/// A printer's swelled rule: the mark between parts of a page. Decoration only: VoiceOver skips it.
struct Ornament: View {
    var color: Color = .brand
    /// How far it reaches to each side of the middle.
    var lineLength: CGFloat = 30
    /// Set to false to pull it into its middle. Animating it to true draws it outward.
    var isDrawn = true

    var body: some View {
        SwelledRuleShape()
            .fill(color)
            .frame(width: lineLength * 2, height: 2.4)
            .scaleEffect(x: isDrawn ? 1 : 0.02)
            .accessibilityHidden(true)
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

/// The frame blind-stamped into a book's cover: a panel with its corners cut in, pressed into the cloth.
struct CoverFrame: View {
    var notch: CGFloat = 9

    var body: some View {
        ZStack {
            NotchedPanel(notch: notch)
                .stroke(Color.black.opacity(0.34), lineWidth: 1)
                .offset(y: -0.5)
            NotchedPanel(notch: notch)
                .stroke(Color.onCover.opacity(0.62), lineWidth: 0.75)
        }
        .accessibilityHidden(true)
    }

    private struct NotchedPanel: Shape {
        let notch: CGFloat

        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + notch, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX, y: rect.minY), radius: notch, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notch))
            path.addArc(center: CGPoint(x: rect.maxX, y: rect.maxY), radius: notch, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX, y: rect.maxY), radius: notch, startAngle: .degrees(0), endAngle: .degrees(270), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + notch))
            path.addArc(center: CGPoint(x: rect.minX, y: rect.minY), radius: notch, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
            path.closeSubpath()
            return path
        }
    }
}

/// A stack of rows set straight on the page, like a table of contents. Open space separates them.
struct Ledger<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small label over one fine line, then its rows, with an optional quiet note below.
struct LedgerSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SmallCapsLabel(title)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 9)
            Rule()
                .padding(.bottom, 4)
            Ledger { content }
            if let footer {
                Text(footer)
                    .font(.versedNote)
                    .foregroundStyle(.secondaryText)
                    .padding(.top, 8)
            }
        }
    }
}

/// One row: a title, an optional detail on the right, and a small arrow.
/// VoiceOver and UI tests read the title as its label and the detail as its value.
struct LedgerRowLabel: View {
    let title: String
    var detail: String? = nil
    /// The small icon at the end of the row, or `nil` for a row that doesn't go anywhere.
    var symbol: Glyph? = .chevronForward
    /// Turns the icon, for a row that opens and closes.
    var symbolAngle: Angle = .zero
    /// Dots from the title to the detail, like a book's table of contents.
    var hasLeader = false

    /// The arrow for rows that leave the app.
    static let externalLinkSymbol = Glyph.arrowUpRight

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
                    .layoutPriority(1)
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
                        .layoutPriority(1)
                }
            }
            if typeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            if let symbol {
                LedgerRowArrow(symbol: symbol)
                    .rotationEffect(symbolAngle)
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
                DrawnCheck(isDrawn: isSelected)
            }
            .ledgerRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.ledgerRow)
        // VoiceOver and UI tests read the title as its label and the detail as its value.
        .accessibilityLabel(title)
        .accessibilityValue(detail ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(trigger: isSelected) { _, nowSelected in nowSelected ? .selection : nil }
    }
}

/// A check mark that writes itself in when chosen, and is gone at once when not.
struct DrawnCheck: View {
    let isDrawn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CheckStroke()
            .trim(from: 0, to: isDrawn ? 1 : 0)
            .stroke(Color.brand, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
            .frame(width: 14, height: 11)
            .animation(isDrawn && !reduceMotion ? .easeOut(duration: 0.26) : nil, value: isDrawn)
            .accessibilityHidden(true)
    }

    private struct CheckStroke: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.36, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            return path
        }
    }
}

/// A date in a row, set in the page's own type. Tapping it opens a calendar beneath it.
struct DateRow: View {
    let title: String
    @Binding var date: Date
    let earliest: Date

    var body: some View {
        OpeningRow(title: title, detail: date.formatted(.dateTime.month(.abbreviated).day().year())) {
            DatePicker(title, selection: $date, in: earliest..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        }
    }
}

/// A time of day in a row. Tapping it opens a wheel beneath it.
struct TimeRow: View {
    let title: String
    @Binding var time: Date

    var body: some View {
        OpeningRow(title: title, detail: time.formatted(date: .omitted, time: .shortened)) {
            DatePicker(title, selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("\(title) Picker")
    }
}

/// A row that opens what's beneath it, moving everything below in step.
private struct OpeningRow<Content: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let content: Content

    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(duration: 0.38, bounce: 0)) { isOpen.toggle() }
            } label: {
                LedgerRowLabel(
                    title: title,
                    detail: detail,
                    symbol: .chevronDown,
                    symbolAngle: .degrees(isOpen ? 180 : 0)
                )
            }
            .buttonStyle(.ledgerRow)
            RevealLayout(progress: isOpen ? 1 : 0) {
                content.opacity(isOpen ? 1 : 0)
            }
            .clipped()
            .allowsHitTesting(isOpen)
            .accessibilityHidden(!isOpen)
        }
    }
}

/// A few short choices side by side. A solid navy plate slides to the one picked.
/// Stacked at the largest text sizes, so a label never breaks in the middle.
struct BlockPicker<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var plate

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(options) { option in
                let isSelected = selection == option
                Button {
                    withAnimation(reduceMotion ? nil : .versed) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.versedDetail)
                        .foregroundStyle(isSelected ? Color("ProminentButtonLabel") : .brand)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if isSelected {
                                Hardcover.corner
                                    .fill(Color("ProminentButton"))
                                    .matchedGeometryEffect(id: "plate", in: plate)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .overlay(Hardcover.corner.strokeBorder(Color.hairline, lineWidth: 1))
        .padding(.top, 6)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// An on/off switch cut like the rest of the book: a nearly square slot with a plate that slides.
/// VoiceOver and UI tests still find a real switch.
struct HardcoverToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Switch(configuration: configuration)
    }

    private struct Switch: View {
        let configuration: Configuration
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        private static let width: CGFloat = 46
        private static let height: CGFloat = 26
        private static let inset: CGFloat = 3

        var body: some View {
            let isOn = configuration.isOn
            HStack {
                configuration.label
                Spacer(minLength: 12)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Hardcover.corner.fill(Color("ProminentButton").opacity(isOn ? 1 : 0))
                    Hardcover.corner.strokeBorder(Color.brand.opacity(isOn ? 0 : 0.45), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isOn ? Color("ProminentButtonLabel") : Color.brand)
                        .frame(width: Self.height - Self.inset * 2, height: Self.height - Self.inset * 2)
                        .padding(Self.inset)
                }
                .frame(width: Self.width, height: Self.height)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .versed) { configuration.isOn.toggle() }
            }
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: isOn)
            .accessibilityRepresentation {
                Toggle(isOn: configuration.$isOn) { configuration.label }
                    .toggleStyle(.switch)
            }
        }
    }
}

/// The dotted line that leads the eye across a table of contents.
struct LeaderDots: View {
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
    var symbol = Glyph.chevronForward

    var body: some View {
        GlyphView(symbol, size: 11)
            .foregroundStyle(.secondaryText)
    }
}

extension View {
    /// The spacing inside a row, tall enough to tap easily.
    func ledgerRowPadding() -> some View {
        padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
    }

    /// The shared margins of a screen's contents.
    func versedPage() -> some View {
        padding(.horizontal, Hardcover.margin)
            .padding(.top, 20)
            .padding(.bottom, 32)
    }

    /// The shared look of a scrolling screen: the paper page, with none of the blur and fade strips
    /// that newer iOS versions draw at the edges of a scrolling screen.
    func versedScreen() -> some View {
        modifier(TabBarClearance())
            .background { PaperSurface() }
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

    /// Every sheet in the app is the same: full height, on the paper page.
    func versedSheet() -> some View {
        environment(\.tabBarClearance, 0)
            .presentationDetents([.large])
            .presentationBackground { PaperSurface() }
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

/// A tappable row: a faint shade of ink under the finger that lifts slowly on release, as native lists do.
struct LedgerRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Hardcover.corner
                    .fill(Color.brand.opacity(configuration.isPressed ? 0.07 : 0))
                    .padding(.horizontal, -10)
            }
            .animation(configuration.isPressed ? .easeOut(duration: 0.05) : .easeOut(duration: 0.32), value: configuration.isPressed)
    }
}

/// A chapter number: the shade stays inside its own square, so neighbors aren't touched.
struct ChapterCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Hardcover.corner
                    .fill(Color.brand.opacity(configuration.isPressed ? 0.09 : 0))
                    .padding(4)
            }
            .animation(configuration.isPressed ? .easeOut(duration: 0.05) : .easeOut(duration: 0.32), value: configuration.isPressed)
    }
}

/// A solid button made like a real plate: a face with a catch of light along its top and a fine
/// darker rim, sitting on a thicker edge that casts a tight shadow. Pressing pushes the face down onto it.
private struct PressedPlate<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let fill: Color
    let ink: Color
    /// How much light catches the top of the face: more on a pale plate, less on a dark one.
    var highlight: Double = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static var edge: CGFloat { 2.5 }

    var body: some View {
        label
            .font(.versedRow)
            .foregroundStyle(ink)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background { face }
            .offset(y: isPressed && !reduceMotion ? Self.edge : 0)
            .background {
                Hardcover.corner
                    .fill(fill)
                    .overlay { Hardcover.corner.fill(Color.black.opacity(0.4)) }
                    .offset(y: Self.edge)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: Self.edge)
            }
            .opacity(isPressed && reduceMotion ? 0.85 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.15), value: isPressed)
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.55), trigger: isPressed) { _, nowPressed in nowPressed }
    }

    private var face: some View {
        Hardcover.corner
            .fill(fill)
            .overlay { TextureTile(name: TextureTile.paper).clipShape(Hardcover.corner) }
            .overlay(alignment: .top) {
                Rule(color: .white.opacity(highlight))
                    .padding(.horizontal, Hardcover.cornerRadius)
                    .padding(.top, 0.5)
            }
            .overlay { Hardcover.corner.strokeBorder(Color.black.opacity(0.16), lineWidth: 0.5) }
    }
}

/// A quieter button with a fine outline, shaded under the finger.
private struct OutlinedPlate<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let ink: Color

    var body: some View {
        label
            .font(.versedRow)
            .foregroundStyle(ink)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(ink.opacity(isPressed ? 0.09 : 0), in: Hardcover.corner)
            .overlay(Hardcover.corner.strokeBorder(ink.opacity(0.42), lineWidth: 0.75))
            .contentShape(Hardcover.corner)
            .pressEffect(isPressed, scale: 0.985)
    }
}

/// The main button: solid navy with cream words (cream with navy words in dark mode).
/// It's as wide as its label; add `.frame(maxWidth: .infinity)` to the label to fill the row.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressedPlate(label: configuration.label, isPressed: configuration.isPressed, fill: Color("ProminentButton"), ink: Color("ProminentButtonLabel"), highlight: 0.16)
    }
}

/// A quieter button: navy words in a fine outline.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OutlinedPlate(label: configuration.label, isPressed: configuration.isPressed, ink: .brand)
    }
}

/// The main button on a navy block: solid cream with navy words, in light and dark mode.
struct CoverPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressedPlate(label: configuration.label, isPressed: configuration.isPressed, fill: .onCover, ink: .cover)
    }
}

/// A quieter button on a navy block: cream words in a fine cream outline.
struct CoverSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OutlinedPlate(label: configuration.label, isPressed: configuration.isPressed, ink: .onCover)
    }
}

/// Words alone, for the small actions at the edge of a screen. Keeps a comfortable tap size.
struct PlainWordButtonStyle: ButtonStyle {
    var ink: Color = .brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.versedDetail)
            .foregroundStyle(ink)
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

extension EnvironmentValues {
    /// How much room the tab bar takes at the foot of a main screen. Nothing in a sheet needs it.
    @Entry var tabBarClearance: CGFloat = 0
}

/// Lets a scrolling screen scroll its last row clear of the tab bar, which sits on top of the page.
private struct TabBarClearance: ViewModifier {
    @Environment(\.tabBarClearance) private var clearance

    func body(content: Content) -> some View {
        content.contentMargins(.bottom, clearance, for: .scrollContent)
    }
}
