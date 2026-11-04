import Foundation

/// One week of the weekly reading schedule. Weeks run Monday through Sunday.
struct ReadingWeek: Identifiable, Hashable, Sendable {
    /// The Monday the week starts, as "yyyy-MM-dd". Stays the same forever, so it's safe to save.
    let id: String
    /// Midnight at the start of Monday.
    let start: Date
    /// Midnight at the start of the following Monday.
    let end: Date
    /// The year's course, such as "New Testament 2027", for grouping weeks in the schedule.
    let course: String
    /// The reading as the schedule prints it, such as "Daniel 1–7".
    let label: String
    let passages: [Passage]
    /// This week's lesson on churchofjesuschrist.org, or the manual's table of contents
    /// if the schedule has no link for the week. Opens in Gospel Library when it's installed.
    let lessonURL: URL

    /// The reading for showing on screen. Ranges like "36–37" never split across two lines:
    /// an invisible "word joiner" on each side of the dash tells iOS not to break there.
    /// VoiceOver labels use `label` instead, so nothing extra is read aloud.
    var displayLabel: String {
        label.replacingOccurrences(of: #"(\d)–(\d)"#, with: "$1\u{2060}–\u{2060}$2", options: .regularExpression)
    }

    /// The reading split by book, for the week's opening card:
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
            book.chapters.compactMap { title in
                guard let firstChapter = Int(title.prefix(while: \.isNumber)),
                      let index = remaining.firstIndex(where: { $0.chapters.lowerBound == firstChapter })
                else { return nil }
                let passage = remaining[index]
                remaining = remaining[remaining.index(after: index)...]
                return ReadingSection(title: title, start: ChapterID(bookID: passage.bookID, chapter: firstChapter))
            }
        }
    }

    func contains(_ date: Date) -> Bool {
        start <= date && date < end
    }

    /// "Nov 2–8", or "Nov 30 – Dec 6" when the week spans two months.
    func dateRangeText(calendar: Calendar = .current) -> String {
        let lastDay = end.addingTimeInterval(-1)
        let month = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.abbreviated)
        let startText = "\(start.formatted(month)) \(calendar.component(.day, from: start))"
        let lastDayNumber = calendar.component(.day, from: lastDay)

        if calendar.isDate(start, equalTo: lastDay, toGranularity: .month) {
            return "\(startText)–\(lastDayNumber)"
        }
        return "\(startText) – \(lastDay.formatted(month)) \(lastDayNumber)"
    }
}

/// One book in a week's reading: its name and the chapters read from it.
struct BookReading: Hashable, Sendable {
    let name: String
    /// Chapters or chapter ranges, such as "1–3" and "47". Empty when the book is read whole.
    let chapters: [String]
}

/// One tappable part of a week's reading, such as "33–34" in Ezekiel.
struct ReadingSection: Hashable, Sendable {
    let title: String
    let start: ChapterID
}
