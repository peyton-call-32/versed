import SwiftUI

/// One verse, filling the screen. Double-tap or tap the heart to save it.
struct VerseCard: View {
    let verse: Verse
    let isSaved: Bool
    /// Double-tapping always saves (it never un-saves), like most feed apps.
    let onDoubleTap: () -> Void
    /// The heart button saves or un-saves.
    let onHeartTap: () -> Void

    @State private var showsHeartBurst = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 20) {
                Text(verse.text)
                    .font(verseFont)
                    .lineSpacing(5)
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
        .padding(.horizontal, 32)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
            showHeartBurst()
        }
        .overlay {
            if showsHeartBurst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.brand)
                    // With Reduce Motion on, the heart fades in place instead of growing.
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            heartButton
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isSaved)
    }

    private var heartButton: some View {
        Button(action: onHeartTap) {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.brand)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 46, height: 46)
                .raised(in: Circle())
                // A slightly bigger tap area than the circle, so it's easy to hit.
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove from saved" : "Save verse")
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        // Clears the tab bar, which floats over the bottom of the feed.
        .padding(.trailing, 20)
        .padding(.bottom, 108)
    }

    private func showHeartBurst() {
        withAnimation(reduceMotion ? .easeIn(duration: 0.2) : .spring(duration: 0.3)) { showsHeartBurst = true }
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeOut(duration: 0.3)) { showsHeartBurst = false }
        }
    }

    /// Shorter verses get bigger text so every verse fills the screen comfortably.
    private var verseFont: Font {
        switch verse.text.count {
        case ..<160: .versedVerse(size: 35)
        case ..<360: .versedVerse(size: 31)
        case ..<600: .versedVerse(size: 26, relativeTo: .title2)
        default: .versedVerse(size: 22, relativeTo: .title3)
        }
    }
}

#Preview {
    @Previewable @State var isSaved = false
    VerseCard(
        verse: Verse(
            id: VerseID(bookID: "1-ne", chapter: 3, verse: 7),
            bookName: "1 Nephi",
            text: "And it came to pass that I, Nephi, said unto my father: I will go and do the things which the Lord hath commanded, for I know that the Lord giveth no commandments unto the children of men, save he shall prepare a way for them that they may accomplish the thing which he commandeth them."
        ),
        isSaved: isSaved,
        onDoubleTap: { isSaved = true },
        onHeartTap: { isSaved.toggle() }
    )
}
