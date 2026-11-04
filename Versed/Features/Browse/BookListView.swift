import SwiftUI

/// The books in one volume.
struct BookListView: View {
    let volume: Volume

    var body: some View {
        ScrollView {
            Card {
                ForEach(volume.books) { book in
                    if book.id != volume.books.first?.id {
                        CardDivider()
                    }
                    NavigationLink(value: route(for: book)) {
                        CardRowLabel(title: book.name, detail: "\(book.chapterCount)")
                    }
                    .buttonStyle(.cardRow)
                }
            }
            .versedPage()
        }
        .background(Color.appBackground)
        .navigationTitle(volume.title)
    }

    /// A book with one chapter (like Enos) opens straight to its reading.
    private func route(for book: Book) -> BrowseView.Route {
        book.chapterCount == 1
            ? .reading(ChapterID(bookID: book.id, chapter: 1))
            : .book(book.id)
    }
}
