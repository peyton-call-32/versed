import Foundation

/// A stretch of reading described by a printed label, such as "Jeremiah 31–33; 36–39; Lamentations 1; 3".
protocol LabeledReading {
    var label: String { get }
    var passages: [Passage] { get }
}

extension LabeledReading {
    /// The reading for showing on screen. Ranges like "36–37" never split across two lines:
    /// an invisible "word joiner" on each side of the dash tells iOS not to break there.
    /// VoiceOver labels use `label` instead, so nothing extra is read aloud.
    var displayLabel: String {
        label.replacingOccurrences(of: #"(\d)–(\d)"#, with: "$1\u{2060}–\u{2060}$2", options: .regularExpression)
    }

    /// The reading split by book, for the opening card:
    /// "Jeremiah 31–33; 36–39" then "Lamentations 1; 3".
    ///
    /// A part after a semicolon starts a new book when it has any letters in it ("Lamentations 1",
    /// "1–3 John"); bare chapters ("36–39") stay with the book before them.
    var displayLabelByBook: [String] {
        var books: [String] = []
        for part in displayLabel.components(separatedBy: "; ") {
            if part.contains(where: \.isLetter) || books.isEmpty {
                books.append(part)
            } else {
                books[books.count - 1] += "; " + part
            }
        }
        return books
    }

    /// Each book in the reading with its chapters, such as "Ezekiel" with "1–3", "33–34",
    /// "36–37", and "47". A book read whole ("Amos", "1 and 2 Peter") has no chapters, and so
    /// does a label with no book at all ("Christmas").
    var readingByBook: [BookReading] {
        displayLabelByBook.map { book in
            var parts = book.components(separatedBy: "; ")
            let first = parts.removeFirst()
            // The first part's chapters are the numbers after the name's last letter:
            // "Joseph Smith—Matthew 1" is "Joseph Smith—Matthew" and "1". Only digits, dashes,
            // and punctuation count, so "1 and 2 Peter" stays whole.
            let pattern = #"^(.*\p{L})\s+([\d\u{2060}–:, ]+)$"#
            guard let match = first.firstMatch(of: try! Regex(pattern)),
                  let name = match.output[1].substring, let chapters = match.output[2].substring
            else {
                return BookReading(name: first, chapters: parts)
            }
            return BookReading(name: String(name), chapters: [String(chapters)] + parts)
        }
    }

    /// The chapter sections of `readingByBook`, one list per book, each with the chapter it starts
    /// on so the opening card can jump there. Matched to `passages` in order, because a number
    /// alone can repeat: "Matthew 1; Luke 1". Books read whole have an empty list.
    var sectionsByBook: [[ReadingSection]] {
        var remaining = passages[...]
        return readingByBook.map { book in
            // A book read whole has no sections, so its passages are passed over: in
            // "Ruth; 1 Samuel 1–7", the "1–7" must not land on Ruth's chapter 1.
            if book.chapters.isEmpty, let bookID = remaining.first?.bookID {
                remaining = remaining.drop { $0.bookID == bookID }
                return []
            }
            return book.chapters.compactMap { title in
                guard let firstChapter = Int(title.prefix(while: \.isNumber)),
                      let index = remaining.firstIndex(where: { $0.chapters.lowerBound == firstChapter })
                else { return nil }
                let passage = remaining[index]
                remaining = remaining[remaining.index(after: index)...]
                return ReadingSection(title: title, start: ChapterID(bookID: passage.bookID, chapter: firstChapter))
            }
        }
    }
}

/// One book in a reading: its name and the chapters read from it.
struct BookReading: Hashable, Sendable {
    let name: String
    /// Chapters or chapter ranges, such as "1–3" and "47". Empty when the book is read whole.
    let chapters: [String]
}

/// One tappable part of a reading, such as "33–34" in Ezekiel.
struct ReadingSection: Hashable, Sendable {
    let title: String
    let start: ChapterID
}

/// One sitting's reading, from a week of the schedule or a day or week of a plan.
/// Holds what its opening and closing cards say.
struct ReadingPortion: LabeledReading, Identifiable, Hashable, Sendable {
    /// Stays the same for the same reading, so its feed keeps its place.
    let id: String
    let label: String
    let passages: [Passage]
    /// The small words on the opening card, such as "This Week · Nov 2–8" or "Day 4 of 57".
    let heading: String
    /// What VoiceOver reads for the opening card's heading.
    let spokenHeading: String
    /// The large words on the closing card, such as "End of Today’s Reading".
    let closingTitle: String
    /// The week's official lesson, for readings from the schedule.
    var lessonURL: URL? = nil
    /// The week of the schedule this reading belongs to, if any.
    var weekID: ReadingWeek.ID? = nil
    /// Where this reading starts in its plan's list of chapters. Zero outside a plan.
    var firstUnit = 0

    /// A whole week of the schedule, read on its own.
    init(week: ReadingWeek, today: Date = VersedApp.today) {
        id = week.id
        label = week.label
        passages = week.passages
        let dates = week.dateRangeText()
        if week.contains(today) {
            heading = "This Week · \(dates)"
            spokenHeading = "This Week, \(week.label), \(dates)"
        } else {
            heading = dates
            spokenHeading = "Week Of, \(week.label), \(dates)"
        }
        closingTitle = Self.endOfWeek
        lessonURL = week.lessonURL
        weekID = week.id
    }

    init(
        id: String,
        label: String,
        passages: [Passage],
        heading: String,
        spokenHeading: String,
        closingTitle: String,
        lessonURL: URL? = nil,
        weekID: ReadingWeek.ID? = nil,
        firstUnit: Int = 0
    ) {
        self.id = id
        self.label = label
        self.passages = passages
        self.heading = heading
        self.spokenHeading = spokenHeading
        self.closingTitle = closingTitle
        self.lessonURL = lessonURL
        self.weekID = weekID
        self.firstUnit = firstUnit
    }

    static let endOfWeek = "End of the Week’s Reading"
    static let endOfDay = "End of Today’s Reading"
    static let endOfReading = "End of the Reading"
    static let endOfPlan = "End of the Plan"
}
