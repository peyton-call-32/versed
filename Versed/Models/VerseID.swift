import Foundation

/// A permanent address for one verse, written as "book.chapter.verse" (for example "1-ne.3.7").
///
/// Saved verses, reading progress, and (later) group activity all point at verses by this ID,
/// so it must never change once the app ships.
struct VerseID: Hashable, Sendable {
    let bookID: String
    let chapter: Int
    let verse: Int

    var rawValue: String { "\(bookID).\(chapter).\(verse)" }

    init(bookID: String, chapter: Int, verse: Int) {
        self.bookID = bookID
        self.chapter = chapter
        self.verse = verse
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ".")
        guard parts.count == 3,
              let chapter = Int(parts[1]),
              let verse = Int(parts[2])
        else { return nil }
        self.init(bookID: String(parts[0]), chapter: chapter, verse: verse)
    }
}

extension VerseID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let id = VerseID(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid verse ID: \(rawValue)")
        }
        self = id
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
