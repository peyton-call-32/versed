import SwiftUI

/// Every chapter number in one book.
struct ChapterGridView: View {
    let book: Book

    var body: some View {
        ScrollView {
            ChapterGrid(chapters: Array(1...book.chapterCount)) { chapter in
                NavigationLink(value: BrowseView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                    ChapterCellLabel(chapter: chapter)
                }
                .buttonStyle(.ledgerRow)
                .accessibilityLabel(book.reference(chapter: chapter))
            }
            .versedPage()
        }
        .versedScreen()
        .navigationTitle(book.name)
        .versedBackButton()
    }
}
