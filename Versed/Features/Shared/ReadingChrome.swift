import Observation
import SwiftUI

/// What floats around the reading pages. While reading a chapter, the tab bar and status bar step
/// aside so only the verse is left. A tap on the page brings them back until the next swipe.
@MainActor
@Observable
final class ReadingChrome {
    /// Whether a chapter or verse page is on screen, in the feed the reader is looking at.
    private(set) var isReading = false
    /// Whether the page on screen is a navy chapter opening.
    private(set) var isOnCover = false
    /// Whether the reader tapped to bring the controls back.
    private(set) var isRevealed = false
    private var activeFeed: UUID?

    /// Whether the controls have stepped aside.
    var hidesControls: Bool { isReading && !isRevealed }

    /// A feed reports the page on screen. `canHide` is false when the reader relies on the controls
    /// always being there, like with VoiceOver on.
    func report(page itemID: FeedItem.ID?, from feed: UUID, canHide: Bool) {
        activeFeed = feed
        let chapter = itemID.flatMap(FeedItem.chapterID(of:))
        isReading = canHide && chapter != nil
        isOnCover = chapter != nil && itemID.flatMap(FeedItem.verseID(of:)) == nil
    }

    /// A feed left the screen. Ignored if another feed has already taken over.
    func leave(_ feed: UUID) {
        guard activeFeed == feed else { return }
        activeFeed = nil
        isReading = false
        isOnCover = false
        isRevealed = false
    }

    func toggleControls() {
        isRevealed.toggle()
    }

    func reveal() {
        isRevealed = true
    }

    func hideRevealedControls() {
        isRevealed = false
    }
}

/// The app's signature spring: quick, with the smallest settle at the end.
extension Animation {
    static let versed = Animation.spring(duration: 0.45, bounce: 0.16)
}

extension View {
    /// For a view the size of a feed page. As the page moves, its contents drift a little slower
    /// than the page and fade, so verses seem to float up from behind the one leaving.
    func pageDepth(drift: CGFloat, fade: CGFloat = 1) -> some View {
        visualEffect { content, proxy in
            let moved = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let progress = min(1, abs(moved) / max(proxy.size.height, 1))
            return content
                .offset(y: -moved * drift)
                .opacity(1 - progress * fade)
        }
    }

    /// A slow, small float, for a hint that points the way. Stays still with Reduce Motion on.
    func gentleBob(isActive: Bool) -> some View {
        modifier(GentleBob(isActive: isActive))
    }
}

private struct GentleBob: ViewModifier {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        // UI tests wait for the app to go still, so the endless float stays off for them.
        if isActive && !reduceMotion && !VersedApp.isUITesting {
            content.phaseAnimator([0, 1]) { view, phase in
                view.offset(y: phase * -5)
            } animation: { _ in
                .easeInOut(duration: 1.3)
            }
        } else {
            content
        }
    }
}
