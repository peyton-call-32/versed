import SwiftUI

/// The five books of scripture as navy hardcovers, one in the middle
/// with the edges of its neighbors showing on each side. Swipe between them, or tap an edge to bring
/// that cover forward. Tapping the cover in the middle opens it.
struct VolumeCarousel: View {
    let volumes: [Volume]
    /// The cover in the middle.
    @Binding var selection: Volume.ID?
    let coverHeight: CGFloat
    let subtitle: (Volume) -> String
    let onOpen: (Volume) -> Void

    /// Where the row starts, so the chosen cover is in the middle from the first frame.
    /// Moving there afterward would also scroll the whole page down to the covers.
    private let startingAnchor: UnitPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverIsOn
    @State private var hasAppeared = false
    @State private var openCount = 0

    init(
        volumes: [Volume],
        selection: Binding<Volume.ID?>,
        coverHeight: CGFloat,
        subtitle: @escaping (Volume) -> String,
        onOpen: @escaping (Volume) -> Void
    ) {
        self.volumes = volumes
        _selection = selection
        self.coverHeight = coverHeight
        self.subtitle = subtitle
        self.onOpen = onOpen
        let index = volumes.firstIndex { $0.id == selection.wrappedValue } ?? 0
        startingAnchor = UnitPoint(x: Double(index) / Double(max(volumes.count - 1, 1)), y: 0.5)
    }

    /// How much of each neighbor shows, and the gap before it.
    private static let edge: CGFloat = 30
    private static let gap: CGFloat = 14

    var body: some View {
        VStack(spacing: 18) {
            ScrollView(.horizontal) {
                HStack(spacing: Self.gap) {
                    ForEach(volumes) { volume in
                        cover(for: volume)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, Self.edge + Self.gap, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .defaultScrollAnchor(startingAnchor)
            .scrollPosition(id: $selection, anchor: .center)
            .scrollIndicators(.hidden)
            // Leaves the covers' shadows whole instead of cutting them off at the top and bottom.
            .scrollClipDisabled()
            .sensoryFeedback(trigger: selection) { old, _ in old == nil ? nil : .selection }

            dots
        }
        .opacity(hasAppeared || reduceMotion ? 1 : 0)
        .offset(y: hasAppeared || reduceMotion ? 0 : 14)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.12)) { hasAppeared = true }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: openCount)
    }

    private func cover(for volume: Volume) -> some View {
        coverButton(id: volume.id) {
            onOpen(volume)
        } label: {
            VolumeCover(title: volume.title, subtitle: subtitle(volume), height: coverHeight)
        }
        .accessibilityLabel(volume.title)
        .accessibilityValue(subtitle(volume))
        .accessibilityHint("Opens this book.")
    }

    /// A cover that opens when it's in the middle, and comes forward when it's at the side.
    private func coverButton(id: Volume.ID, open: @escaping () -> Void, @ViewBuilder label: () -> some View) -> some View {
        Button {
            // VoiceOver reaches each cover directly, so there's nothing to bring forward first.
            if id == selection || voiceOverIsOn {
                openCount += 1
                open()
            } else {
                withAnimation(reduceMotion ? nil : .versed) { selection = id }
            }
        } label: {
            label()
        }
        .buttonStyle(CoverButtonStyle())
        // The space left between the margins, which is what leaves the neighbors' edges showing.
        .containerRelativeFrame(.horizontal)
        .scrollTransition(axis: .horizontal) { content, phase in
            content.scaleEffect(phase.isIdentity || reduceMotion ? 1 : 0.95)
        }
    }

    /// One dot per cover, with the current one in full ink. Decoration only: VoiceOver
    /// reads the covers themselves.
    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(volumes.map(\.id), id: \.self) { id in
                Circle()
                    .fill(id == selection ? Color.brand : Color.brand.opacity(0.22))
                    .frame(width: 5, height: 5)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selection)
        .accessibilityHidden(true)
        .accessibilityIdentifier("Book dots")
    }
}

/// A book of scripture's cover: its name, with how many books or sections it holds at the foot.
private struct VolumeCover: View {
    let title: String
    let subtitle: String
    let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CoverBoard(height: height) {
            Text(CoverTitle.lines(for: title))
                .font(.versedTitle(size: 44))
                .lineSpacing(-2)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)
                .foregroundStyle(.onCover)
                .titleDrift(by: reduceMotion ? 0 : 0.12)
        } foot: {
            SmallCapsLabel(subtitle, color: .onCover)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// The cover for the weekly schedule, at the top of Browse. Its words all live here, so they're easy
/// to change. They name the manual and say plainly that the Church didn't make the app.
struct WeeklyCover: View {
    static let id = "weekly-reading"
    static let title = "Come, Follow Me"
    static let subtitle = "For Home and Church"
    static let notice = "Versed is an independent app, not made or endorsed by The Church of Jesus Christ of Latter-day Saints."

    /// The manual's whole title, as VoiceOver reads it.
    static func spokenTitle(course: String) -> String {
        "\(title)—\(subtitle): \(course)"
    }

    /// The course the calendar is on, such as "Old Testament 2026". It changes with the year.
    let course: String
    let height: CGFloat

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        CoverBoard(height: height) {
            VStack(spacing: 6) {
                Text(Self.title)
                    .font(.versedTitle(size: 40))
                    .lineLimit(1)
                VStack(spacing: 2) {
                    Text(Self.subtitle)
                    Text(course)
                }
                .font(.versedTitle(size: 21, relativeTo: .title2))
                .lineLimit(1)
                // Stays smaller than the title, which shrinks to fit on one line at the largest sizes.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.55)
            .foregroundStyle(.onCover)
        } foot: {
            Text(Self.notice)
                .font(.versedVerse(size: 11, relativeTo: .caption2))
                .lineSpacing(1)
                .multilineTextAlignment(.center)
                // Two lines, unless the reader's text size needs more to stay readable.
                .lineLimit(typeSize.isAccessibilitySize ? 6 : 2)
                .minimumScaleFactor(typeSize.isAccessibilitySize ? 0.55 : 0.85)
                .foregroundStyle(.onCover)
        }
    }
}

/// One hardcover: solid navy and a thin double border, with cream words set in the middle and at the foot.
private struct CoverBoard<Middle: View, Foot: View>: View {
    let height: CGFloat
    @ViewBuilder let middle: Middle
    @ViewBuilder let foot: Foot

    var body: some View {
        ZStack {
            border
            VStack(spacing: 0) {
                Ornament(color: .onCover)
                Spacer(minLength: 8)
                middle
                Spacer(minLength: 8)
                foot
            }
            .padding(.leading, 34)
            .padding(.trailing, 26)
            .padding(.vertical, 34)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background {
            Hardcover.corner
                .fill(Color.cover)
                .shadow(color: .cardShadow, radius: 14, y: 10)
        }
        .contentShape(Hardcover.corner)
    }

    /// The frame, with a thin groove down the left where a real cover hinges at the spine.
    private var border: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.onCover.opacity(0.2))
                .frame(width: 1)
                .padding(.leading, 9)
            CoverFrame()
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
        }
    }
}

/// Splits a book's name into balanced lines for its cover: "Book of / Mormon".
enum CoverTitle {
    static func lines(for title: String) -> String {
        let words = title.split(separator: " ").map(String.init)
        guard words.count > 1 else { return title }
        let bestBreak = (1..<words.count).min { first, second in
            longestLine(words, breakingAt: first) < longestLine(words, breakingAt: second)
        } ?? 1
        return words[..<bestBreak].joined(separator: " ") + "\n" + words[bestBreak...].joined(separator: " ")
    }

    private static func longestLine(_ words: [String], breakingAt index: Int) -> Int {
        max(words[..<index].joined(separator: " ").count, words[index...].joined(separator: " ").count)
    }
}

/// A cover gives slightly under the finger: it presses in with a soft spring.
struct CoverButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pressEffect(configuration.isPressed, scale: 0.975)
    }
}

private extension View {
    /// As a cover slides, its title moves a little against the cover, for a sense of depth.
    /// On the covers at the sides, this also keeps the title out of the edge that shows.
    func titleDrift(by amount: CGFloat) -> some View {
        visualEffect { content, proxy in
            let frame = proxy.frame(in: .scrollView(axis: .horizontal))
            let visibleWidth = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? frame.width
            return content.offset(x: (frame.midX - visibleWidth / 2) * amount)
        }
    }
}
