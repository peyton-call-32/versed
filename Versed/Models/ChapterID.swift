import Foundation

/// A permanent address for one chapter, written as "book.chapter" (for example "jer.31").
struct ChapterID: Hashable, Sendable {
    let bookID: String
    let chapter: Int

    var rawValue: String { "\(bookID).\(chapter)" }

    init(bookID: String, chapter: Int) {
        self.bookID = bookID
        self.chapter = chapter
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ".")
        guard parts.count == 2, let chapter = Int(parts[1]) else { return nil }
        self.init(bookID: String(parts[0]), chapter: chapter)
    }
}
