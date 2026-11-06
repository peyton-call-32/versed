import SwiftUI

/// Every chapter number in one book.
struct ChapterGridView: View {
    let book: Book
    /// Starts a plan for this book, or opens the one already going.
    let startPlan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Ledger {
                    Button(action: startPlan) {
                        LedgerRowLabel(title: "Make a Plan for This Book")
                    }
                    .buttonStyle(.ledgerRow)
                }
                ChapterGrid(chapters: Array(1...book.chapterCount)) { chapter in
                    NavigationLink(value: LibraryView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                        ChapterCellLabel(chapter: chapter)
                    }
                    .buttonStyle(.ledgerRow)
                    .accessibilityLabel(book.reference(chapter: chapter))
                }
            }
            .versedPage()
        }
        .versedScreen()
        .navigationTitle(book.name)
        .versedBackButton()
    }
}
