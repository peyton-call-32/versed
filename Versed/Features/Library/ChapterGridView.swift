import SwiftUI

/// Every chapter number in one book.
struct ChapterGridView: View {
    let book: Book
    /// Starts a plan for this book, or opens the one already going.
    let startPlan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Hardcover.sectionSpacing) {
                Ledger {
                    Button(action: startPlan) {
                        LedgerRowLabel(title: book.makePlanTitle)
                    }
                    .buttonStyle(.ledgerRow)
                }
                ChapterGrid(chapters: Array(1...book.chapterCount)) { chapter in
                    NavigationLink(value: LibraryView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                        ChapterCellLabel(chapter: chapter)
                    }
                    .buttonStyle(ChapterCellButtonStyle())
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
