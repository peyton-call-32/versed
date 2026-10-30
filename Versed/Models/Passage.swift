import Foundation

/// A stretch of scripture to read, written as text so schedules stay easy to edit by hand:
///
/// - `"jer.31"`: one chapter
/// - `"jer.31-33"`: several chapters
/// - `"isa.53.3-5"`: some verses in one chapter
/// - `"isa.61.1"`: one verse
struct Passage: Hashable, Sendable {
    let bookID: String
    let chapters: ClosedRange<Int>
    /// Which verses to read, or `nil` for whole chapters. Only used when `chapters` is a single chapter.
    let verses: ClosedRange<Int>?

    init(bookID: String, chapters: ClosedRange<Int>, verses: ClosedRange<Int>? = nil) {
        self.bookID = bookID
        self.chapters = chapters
        self.verses = verses
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: ".").map(String.init)
        guard (2...3).contains(parts.count),
              let chapters = Self.range(from: parts[1])
        else { return nil }

        if parts.count == 3 {
            guard chapters.count == 1, let verses = Self.range(from: parts[2]) else { return nil }
            self.init(bookID: parts[0], chapters: chapters, verses: verses)
        } else {
            self.init(bookID: parts[0], chapters: chapters)
        }
    }

    var rawValue: String {
        var text = "\(bookID).\(Self.text(for: chapters))"
        if let verses {
            text += ".\(Self.text(for: verses))"
        }
        return text
    }

    /// Reads "31" or "31-33".
    private static func range(from text: String) -> ClosedRange<Int>? {
        let bounds = text.split(separator: "-").compactMap { Int($0) }
        switch bounds.count {
        case 1 where bounds[0] > 0: return bounds[0]...bounds[0]
        case 2 where bounds[0] > 0 && bounds[0] <= bounds[1]: return bounds[0]...bounds[1]
        default: return nil
        }
    }

    private static func text(for range: ClosedRange<Int>) -> String {
        range.count == 1 ? "\(range.lowerBound)" : "\(range.lowerBound)-\(range.upperBound)"
    }
}

extension Passage: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let passage = Passage(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid passage: \(rawValue)")
        }
        self = passage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
