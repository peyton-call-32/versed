import SwiftUI

/// One verse, filling the screen. Double-tap or tap the heart to save it; a single tap brings
/// back the controls that step aside while reading.
struct VerseCard: View {
    let verse: Verse
    let isSaved: Bool
    /// Double-tapping always saves (it never un-saves), like most feed apps.
    let onDoubleTap: () -> Void
    /// The heart button saves or un-saves.
    let onHeartTap: () -> Void
    var onTap: () -> Void = {}
    /// Whether the tab bar is showing, so the heart moves up out of its way.
    var liftsHeart = false

    /// Where the double-tap landed, while its heart is on screen.
    @State private var burst: HeartBurst?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct HeartBurst: Identifiable {
        let id = UUID()
        let location: CGPoint
    }

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 20) {
                VerseText(verse.text, size: verseSize.points, relativeTo: verseSize.style)
                    .lineSpacing(6)
                    .foregroundStyle(.brand)

                VStack(spacing: 14) {
                    Ornament()
                    SmallCapsLabel(verse.reference)
                }
                .padding(.top, 6)
            }
            // VoiceOver reads the reference, then the verse, as one item.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(verse.reference)
            .accessibilityValue(verse.text)
            .accessibilityAction(named: isSaved ? "Remove from Saved" : "Save Verse", onHeartTap)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageDepth(drift: reduceMotion ? 0 : 0.14, fade: 1)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { location in
            onDoubleTap()
            showHeartBurst(at: location)
        }
        .onTapGesture(perform: onTap)
        .overlay {
            if let burst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(.brand)
                    .rotationEffect(.degrees(reduceMotion ? 0 : -8))
                    .position(burst.location)
                    .id(burst.id)
                    // It pops in where the finger landed, then floats up and away.
                    // With Reduce Motion on, it simply fades.
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .scale(scale: 0.35).combined(with: .opacity),
                        removal: .offset(y: -70).combined(with: .opacity)
                    ))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            heartButton
        }
        // A soft tap when saving, and just a tick when taking it back.
        .sensoryFeedback(trigger: isSaved) { _, nowSaved in
            nowSaved ? .impact(flexibility: .soft, intensity: 0.9) : .selection
        }
    }

    private var heartButton: some View {
        Button(action: onHeartTap) {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 25, weight: .light))
                .foregroundStyle(.brand)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isSaved)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove from saved" : "Save verse")
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.trailing, 22)
        // Sits above the progress line, or above the tab bar when it's showing.
        .padding(.bottom, liftsHeart ? 108 : FeedInsets.progressBar + 22)
        .animation(reduceMotion ? nil : .versed, value: liftsHeart)
    }

    private func showHeartBurst(at location: CGPoint) {
        let next = HeartBurst(location: location)
        withAnimation(reduceMotion ? .easeIn(duration: 0.2) : .spring(duration: 0.35, bounce: 0.45)) { burst = next }
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            // A newer double-tap keeps its own heart on screen.
            guard burst?.id == next.id else { return }
            withAnimation(.easeOut(duration: 0.45)) { burst = nil }
        }
    }

    /// Shorter verses get bigger text so every verse fills the screen comfortably.
    private var verseSize: (points: CGFloat, style: Font.TextStyle) {
        switch verse.text.count {
        case ..<160: (33, .title)
        case ..<360: (29, .title)
        case ..<600: (25, .title2)
        default: (21, .title3)
        }
    }
}

#Preview {
    @Previewable @State var isSaved = false
    VerseCard(
        verse: Verse(
            id: VerseID(bookID: "jer", chapter: 31, verse: 3),
            bookName: "Jeremiah",
            text: "The LORD hath appeared of old unto me, saying, Yea, I have loved thee with an everlasting love: therefore with lovingkindness have I drawn thee."
        ),
        isSaved: isSaved,
        onDoubleTap: { isSaved = true },
        onHeartTap: { isSaved.toggle() }
    )
}
