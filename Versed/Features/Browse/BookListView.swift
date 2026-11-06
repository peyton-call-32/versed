import SwiftUI

/// The books in one volume.
struct BookListView: View {
    let volume: Volume
    /// Starts a plan for the whole volume, or opens the one already going.
    let startPlan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Ledger {
                    Button(action: startPlan) {
                        LedgerRowLabel(title: "Make a Plan for All \(volume.books.count) Books")
                    }
                    .buttonStyle(.ledgerRow)
                }
                Ledger {
                ForEach(volume.books) { book in
                    if book.id != volume.books.first?.id {
                        LedgerRule()
                    }
                    NavigationLink(value: route(for: book)) {
                        LedgerRowLabel(title: book.name, detail: "\(book.chapterCount)", symbol: nil, hasLeader: true)
                    }
                    .buttonStyle(.ledgerRow)
                }
                }
            }
            .versedPage()
        }
        .versedScreen()
        .navigationTitle(volume.title)
        .versedBackButton()
    }

    /// A book with one chapter (like Enos) opens straight to its reading.
    private func route(for book: Book) -> BrowseView.Route {
        book.chapterCount == 1
            ? .reading(ChapterID(bookID: book.id, chapter: 1))
            : .book(book.id)
    }
}
