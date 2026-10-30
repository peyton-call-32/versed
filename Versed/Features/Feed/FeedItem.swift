import Foundation

/// One full-screen page in the feed.
enum FeedItem: Identifiable, Hashable, Sendable {
    /// The opening card for a week's reading.
    case weekIntro(ReadingWeek)
    /// The card shown before the first verse of a chapter.
    case chapterTitle(ChapterTitle)
    case verse(Verse)

    var id: String {
        switch self {
        case .weekIntro(let week): "week:\(week.id)"
        case .chapterTitle(let title): "chapter:\(title.id.rawValue)"
        case .verse(let verse): Self.id(for: verse.id)
        }
    }

    /// The feed ID of a verse's page, for jumping straight to it.
    static func id(for verseID: VerseID) -> ID {
        "verse:\(verseID.rawValue)"
    }
}

struct ChapterTitle: Hashable, Sendable {
    let id: ChapterID
    let bookName: String
    /// "Chapter 31" or "Section 76".
    let heading: String
}

extension ScriptureLibrary {
    /// Builds the feed for a list of passages, in order.
    ///
    /// A chapter gets a title card when the reading starts at its first verse.
    /// Verses that appear more than once are only shown the first time, and passages that don't exist are skipped.
    func feedItems(for passages: [Passage]) -> [FeedItem] {
        var items: [FeedItem] = []
        var seenIDs: Set<FeedItem.ID> = []

        func append(_ item: FeedItem) {
            if seenIDs.insert(item.id).inserted {
                items.append(item)
            }
        }

        for passage in passages {
            guard let book = book(id: passage.bookID) else { continue }

            for chapter in passage.chapters {
                let verses = book.verses(inChapter: chapter).filter { verse in
                    passage.verses?.contains(verse.id.verse) ?? true
                }
                guard let firstVerse = verses.first else { continue }

                if firstVerse.id.verse == 1 {
                    let chapterID = ChapterID(bookID: book.id, chapter: chapter)
                    append(.chapterTitle(ChapterTitle(id: chapterID, bookName: book.name, heading: book.heading(chapter: chapter))))
                }
                verses.forEach { append(.verse($0)) }
            }
        }
        return items
    }
}
