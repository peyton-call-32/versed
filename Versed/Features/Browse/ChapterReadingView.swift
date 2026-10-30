import SwiftUI

/// Reads a book in the feed, starting at the chosen chapter and continuing to the end of the book.
struct ChapterReadingView: View {
    let library: ScriptureLibrary
    let book: Book
    let startChapter: Int
    /// Opens on this verse of the start chapter instead of the chapter's title card.
    var startVerse: Int? = nil

    var body: some View {
        FeedView(
            items: library.feedItems(for: [Passage(bookID: book.id, chapters: startChapter...book.chapterCount)]),
            startingAt: startVerse.map { FeedItem.id(for: VerseID(bookID: book.id, chapter: startChapter, verse: $0)) }
        )
        // The title cards already name the book, so the bar only shows the back button.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
