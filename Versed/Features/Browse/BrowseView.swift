import SwiftUI

/// Pick any volume, book, and chapter, then read from there in the feed.
struct BrowseView: View {
    let library: ScriptureLibrary

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case volume(Volume.ID)
        case book(Book.ID)
        case reading(ChapterID)
    }

    var body: some View {
        NavigationStack {
            List(library.volumes) { volume in
                NavigationLink(value: route(for: volume)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(volume.title)
                            .font(.system(.title3, design: .serif))
                        Text(subtitle(for: volume))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Browse")
            .navigationDestination(for: Route.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .volume(let id):
            if let volume = library.volume(id: id) {
                BookListView(volume: volume)
            }
        case .book(let id):
            if let book = library.book(id: id) {
                ChapterGridView(book: book)
            }
        case .reading(let chapterID):
            if let book = library.book(id: chapterID.bookID) {
                ChapterReadingView(library: library, book: book, startChapter: chapterID.chapter)
            }
        }
    }

    /// A volume with a single book (the Doctrine and Covenants) skips straight to its chapters.
    private func route(for volume: Volume) -> Route {
        if volume.books.count == 1, let book = volume.books.first {
            return .book(book.id)
        }
        return .volume(volume.id)
    }

    /// "39 books" or "138 sections".
    private func subtitle(for volume: Volume) -> String {
        if volume.books.count == 1, let book = volume.books.first {
            return "\(book.chapterCount) \((book.chapterLabel ?? "Chapter").lowercased())s"
        }
        return "\(volume.books.count) books"
    }
}

#Preview {
    BrowseView(library: try! ScriptureLibrary.loadBundled())
}
