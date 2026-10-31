import SwiftUI

/// The books in one volume.
struct BookListView: View {
    let volume: Volume

    var body: some View {
        List(volume.books) { book in
            NavigationLink(value: route(for: book)) {
                HStack {
                    Text(book.name)
                    Spacer()
                    Text("\(book.chapterCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle(volume.title)
    }

    /// A book with one chapter (like Enos) opens straight to its reading.
    private func route(for book: Book) -> BrowseView.Route {
        book.chapterCount == 1
            ? .reading(ChapterID(bookID: book.id, chapter: 1))
            : .book(book.id)
    }
}
