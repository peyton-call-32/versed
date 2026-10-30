import SwiftUI

/// Reads a book in the feed, starting at the chosen chapter and continuing to the end of the book.
struct ChapterReadingView: View {
    let library: ScriptureLibrary
    let book: Book
    let startChapter: Int

    var body: some View {
        FeedView(items: library.feedItems(for: [Passage(bookID: book.id, chapters: startChapter...book.chapterCount)]))
            // The title cards already name the book, so the bar only shows the back button.
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
