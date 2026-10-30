import Foundation

/// A permanent address for one chapter, written as "book.chapter" (for example "jer.31").
struct ChapterID: Hashable, Sendable {
    let bookID: String
    let chapter: Int

    var rawValue: String { "\(bookID).\(chapter)" }
}
