import Observation

/// Connects a feed to the controls that move around in it, like the chapter menu and the tab bar.
/// The feed reports the page on screen here, and the controls ask it to move from here.
@MainActor
@Observable
final class FeedNavigation {
    enum Request: Equatable {
        case chapter(ChapterID)
        case start
    }

    /// The page on screen, as reported by the feed.
    var visibleItemID: FeedItem.ID?
    /// A move the feed hasn't made yet. The feed clears it once it has.
    var request: Request?

    /// Goes to a chapter's first page.
    func go(to chapter: ChapterID) {
        request = .chapter(chapter)
    }

    /// Goes back to the feed's first page.
    func goToStart() {
        request = .start
    }
}
