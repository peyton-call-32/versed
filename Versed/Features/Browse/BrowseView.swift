import SwiftData
import SwiftUI

/// Pick any volume, book, and chapter, then read from there in the feed.
/// A "Continue Reading" row at the top returns to the last page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary

    @Query private var positions: [ReadingPosition]

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case volume(Volume.ID)
        case book(Book.ID)
        case reading(ChapterID)
        /// Reopens the feed on a saved page.
        case resume(FeedItem.ID)
    }

    var body: some View {
        NavigationStack {
            List {
                if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
                    Section("Continue Reading") {
                        NavigationLink(value: Route.resume(itemID)) {
                            Label(reference, systemImage: "bookmark")
                                .font(.system(.body, design: .serif))
                        }
                    }
                }

                Section {
                    ForEach(library.volumes) { volume in
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
        case .resume(let itemID):
            if let chapterID = FeedItem.chapterID(of: itemID), let book = library.book(id: chapterID.bookID) {
                ChapterReadingView(library: library, book: book, startChapter: chapterID.chapter, startItem: itemID)
            }
        }
    }

    private var lastBrowsePosition: FeedItem.ID? {
        positions.first { $0.feed == ReadingFeed.browse.key }?.itemID
    }

    /// "Alma 32:21" for a verse page, or "Alma 32" for a chapter's title card.
    private func reference(for itemID: FeedItem.ID) -> String? {
        guard let chapterID = FeedItem.chapterID(of: itemID),
              let book = library.book(id: chapterID.bookID)
        else { return nil }

        if let verseID = FeedItem.verseID(of: itemID), let verse = library.verse(verseID) {
            return verse.reference
        }
        return book.reference(chapter: chapterID.chapter)
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
        .modelContainer(for: [SavedVerse.self, ReadingPosition.self], inMemory: true)
}
