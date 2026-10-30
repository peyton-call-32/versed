import Foundation

/// One volume of scripture, such as the Book of Mormon.
struct Volume: Decodable, Identifiable, Sendable {
    let id: String
    let title: String
    let books: [Book]
}

/// One book, such as 1 Nephi. The Doctrine and Covenants is stored as a single book whose chapters are sections.
struct Book: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    /// Shorter name used in references, such as "D&C". Falls back to `name`.
    let shortName: String?
    /// What a chapter is called in this book. Falls back to "Chapter".
    let chapterLabel: String?
    /// The text of every verse, grouped by chapter. Verse N of chapter C is `chapters[C - 1][N - 1]`.
    let chapters: [[String]]

    var referenceName: String { shortName ?? name }
    var chapterCount: Int { chapters.count }

    /// "1 Nephi 3" or "D&C 76".
    func reference(chapter: Int) -> String {
        "\(referenceName) \(chapter)"
    }

    /// "Chapter 31" or "Section 76".
    func heading(chapter: Int) -> String {
        "\(chapterLabel ?? "Chapter") \(chapter)"
    }

    /// All verses in a chapter, or an empty list if the chapter doesn't exist.
    func verses(inChapter chapter: Int) -> [Verse] {
        guard chapters.indices.contains(chapter - 1) else { return [] }
        return chapters[chapter - 1].enumerated().map { index, text in
            Verse(id: VerseID(bookID: id, chapter: chapter, verse: index + 1), bookName: referenceName, text: text)
        }
    }
}

/// A single verse, ready to show on screen.
struct Verse: Identifiable, Hashable, Sendable {
    let id: VerseID
    let bookName: String
    let text: String

    /// "1 Nephi 3:7"
    var reference: String {
        "\(bookName) \(id.chapter):\(id.verse)"
    }
}
