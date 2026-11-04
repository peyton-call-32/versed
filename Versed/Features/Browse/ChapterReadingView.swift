import SwiftData
import SwiftUI

/// Reads a whole book in the feed, opening at the chosen chapter. The chapter menu moves to any
/// other chapter in the book.
///
/// The page on screen is remembered so the Browse tab can offer to continue from it.
struct ChapterReadingView: View {
    let library: ScriptureLibrary
    let book: Book
    let startChapter: Int
    /// Opens on this page of the start chapter instead of the chapter's title card.
    var startItem: FeedItem.ID? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var navigation = FeedNavigation()

    private var items: [FeedItem] {
        library.feedItems(for: [Passage(bookID: book.id, chapters: 1...book.chapterCount)])
    }

    var body: some View {
        let positions = ReadingPositionStore(context: modelContext)
        let items = items
        FeedView(
            items: items,
            startingAt: startItem ?? items.first { FeedItem.chapterID(of: $0.id)?.chapter == startChapter }?.id,
            navigation: navigation,
            onPageChange: { positions.setPosition($0, in: .browse) }
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChapterMenu(library: library, items: items, navigation: navigation)
            }
        }
        // The pill and title cards already say where the reader is, so the bar has no title.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
