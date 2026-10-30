import SwiftData
import SwiftUI

/// Reads a book in the feed, starting at the chosen chapter and continuing to the end of the book.
///
/// The page on screen is remembered so the Browse tab can offer to continue from it.
struct ChapterReadingView: View {
    let library: ScriptureLibrary
    let book: Book
    let startChapter: Int
    /// Opens on this page of the start chapter instead of the chapter's title card.
    var startItem: FeedItem.ID? = nil

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let positions = ReadingPositionStore(context: modelContext)
        FeedView(
            items: library.feedItems(for: [Passage(bookID: book.id, chapters: startChapter...book.chapterCount)]),
            startingAt: startItem,
            onPageChange: { positions.setPosition($0, in: .browse) }
        )
        // The title cards already name the book, so the bar only shows the back button.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
