import Foundation

/// One full-screen page in the feed.
enum FeedItem: Identifiable, Hashable, Sendable {
    /// The opening card for a reading.
    case opening(ReadingPortion)
    /// The closing card after a reading's last verse.
    case closing(ReadingPortion)
    /// The card shown before the first verse of a chapter.
    case chapterTitle(ChapterTitle)
    case verse(Verse)

    var id: String {
        switch self {
        case .opening(let reading): "week:\(reading.id)"
        case .closing(let reading): "week-end:\(reading.id)"
        case .chapterTitle(let title): "chapter:\(title.id.rawValue)"
        case .verse(let verse): Self.id(for: verse.id)
        }
    }

    /// The feed ID of a verse's page, for jumping straight to it.
    static func id(for verseID: VerseID) -> ID {
        "verse:\(verseID.rawValue)"
    }

    /// The verse a page shows, read back from its feed ID, or `nil` if it isn't a verse page.
    static func verseID(of id: ID) -> VerseID? {
        id.dropPrefix("verse:").flatMap(VerseID.init(rawValue:))
    }

    /// The chapter a page belongs to, read back from its feed ID, or `nil` for a reading's opening or closing card.
    static func chapterID(of id: ID) -> ChapterID? {
        if let verseID = verseID(of: id) {
            return ChapterID(bookID: verseID.bookID, chapter: verseID.chapter)
        }
        return id.dropPrefix("chapter:").flatMap(ChapterID.init(rawValue:))
    }
}

private extension String {
    func dropPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}

struct ChapterTitle: Hashable, Sendable {
    let id: ChapterID
    let bookName: String
    /// "Chapter" or "Section" (Doctrine and Covenants).
    let label: String

    /// "Chapter 31" or "Section 76".
    var heading: String { "\(label) \(id.chapter)" }
}

/// Chapters in a feed from one book, for the chapter menu.
struct ChapterGroup: Sendable {
    let book: Book
    var chapters: [Int]
}

extension ScriptureLibrary {
    /// The chapters in a feed, in reading order and each listed once. A new group starts each
    /// time the book changes, so "Luke 1; Matthew 1; Luke 2" stays three groups, in that order.
    func chapterGroups(in items: [FeedItem]) -> [ChapterGroup] {
        var groups: [ChapterGroup] = []
        var seen: Set<ChapterID> = []
        for item in items {
            guard let chapter = FeedItem.chapterID(of: item.id), seen.insert(chapter).inserted else { continue }
            if groups.last?.book.id == chapter.bookID {
                groups[groups.count - 1].chapters.append(chapter.chapter)
            } else if let book = book(id: chapter.bookID) {
                groups.append(ChapterGroup(book: book, chapters: [chapter.chapter]))
            }
        }
        return groups
    }

    /// A reading's whole feed: its opening card, its verses, and its closing card.
    func feedItems(for reading: ReadingPortion) -> [FeedItem] {
        [.opening(reading)] + feedItems(for: reading.passages) + [.closing(reading)]
    }

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
                    append(.chapterTitle(ChapterTitle(id: chapterID, bookName: book.name, label: book.chapterWord)))
                }
                verses.forEach { append(.verse($0)) }
            }
        }
        return items
    }
}
