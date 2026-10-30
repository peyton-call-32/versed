import Foundation

/// One full-screen page in the feed: either a chapter's title card or a single verse.
enum FeedItem: Identifiable, Hashable, Sendable {
    case chapterTitle(ChapterTitle)
    case verse(Verse)

    var id: String {
        switch self {
        case .chapterTitle(let title): "chapter:\(title.id.rawValue)"
        case .verse(let verse): "verse:\(verse.id.rawValue)"
        }
    }
}

/// The card shown before the first verse of each chapter.
struct ChapterTitle: Hashable, Sendable {
    let id: ChapterID
    let bookName: String
    /// "Chapter 31" or "Section 76".
    let heading: String
}

extension ScriptureLibrary {
    /// Builds the feed for a list of chapters: a title card, then each verse, for every chapter in order.
    /// Chapters that don't exist are skipped.
    func feedItems(for chapters: [ChapterID]) -> [FeedItem] {
        chapters.flatMap { chapterID -> [FeedItem] in
            guard let book = book(id: chapterID.bookID) else { return [] }
            let verses = book.verses(inChapter: chapterID.chapter)
            guard !verses.isEmpty else { return [] }

            let title = ChapterTitle(id: chapterID, bookName: book.name, heading: book.heading(chapter: chapterID.chapter))
            return [.chapterTitle(title)] + verses.map(FeedItem.verse)
        }
    }
}
