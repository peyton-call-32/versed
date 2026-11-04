import SwiftUI

/// The five books of scripture as navy hardcovers, one in the middle with the edges of its
/// neighbors showing on each side. Swipe between them, or tap an edge to bring that book forward.
/// Tapping the book in the middle opens it, zooming out of its cover on iOS 18 and later.
struct VolumeCarousel: View {
    let volumes: [Volume]
    /// The book in the middle.
    @Binding var selection: Volume.ID?
    let coverHeight: CGFloat
    /// Shared with the screen the cover opens, for the zoom.
    let zoomNamespace: Namespace.ID
    let subtitle: (Volume) -> String
    let onOpen: (Volume) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverIsOn
    @State private var hasAppeared = false
    @State private var openCount = 0

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
        Button {
            // VoiceOver reaches each cover directly, so there's nothing to bring forward first.
            if volume.id == selection || voiceOverIsOn {
                openCount += 1
                onOpen(volume)
            } else {
                withAnimation(reduceMotion ? nil : .versed) { selection = volume.id }
            }
        } label: {
            VolumeCover(title: volume.title, subtitle: subtitle(volume), height: coverHeight)
        }
        .buttonStyle(CoverButtonStyle())
        .coverZoomSource(id: volume.id, in: zoomNamespace)
        // The space left between the margins, which is what leaves the neighbors' edges showing.
        .containerRelativeFrame(.horizontal)
        .scrollTransition(axis: .horizontal) { content, phase in
            content.scaleEffect(phase.isIdentity || reduceMotion ? 1 : 0.95)
        }
        .accessibilityLabel(volume.title)
        .accessibilityValue(subtitle(volume))
        .accessibilityHint("Opens this book.")
    }

    /// One dot per book. The current one stretches into a short bar. Decoration only: VoiceOver
    /// reads the covers themselves.
    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(volumes) { volume in
                Capsule()
                    .fill(volume.id == selection ? Color.brand : Color.brand.opacity(0.22))
                    .frame(width: volume.id == selection ? 20 : 6, height: 6)
            }
        }
        .animation(reduceMotion ? nil : .versed, value: selection)
        .accessibilityHidden(true)
        .accessibilityIdentifier("Book dots")
    }
}

/// One hardcover: solid navy, a thin double border, and the book's name in cream.
private struct VolumeCover: View {
    let title: String
    let subtitle: String
    let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            border
            VStack(spacing: 0) {
                Ornament(color: .onCover)
                Spacer(minLength: 8)
                Text(CoverTitle.lines(for: title))
                    .font(.versedTitle(size: 44))
                    .lineSpacing(-2)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.55)
                    .foregroundStyle(.onCover)
                    .titleDrift(by: reduceMotion ? 0 : 0.12)
                Spacer(minLength: 8)
                SmallCapsLabel(subtitle, color: .onCover)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 34)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.cover)
                .shadow(color: Color.cover.opacity(0.3), radius: 18, y: 12)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var border: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.onCover.opacity(0.5))
                .padding(9)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.onCover.opacity(0.22))
                .padding(14)
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
private struct CoverButtonStyle: ButtonStyle {
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

extension View {
    /// Marks a cover as where the zoom into its book starts. Does nothing before iOS 18.
    @ViewBuilder
    func coverZoomSource(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            matchedTransitionSource(id: id, in: namespace) { source in
                source.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        } else {
            self
        }
    }

    /// Opens this screen by zooming out of a cover. A plain slide before iOS 18.
    @ViewBuilder
    func zoomsFromCover(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
