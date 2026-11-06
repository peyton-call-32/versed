import Foundation
import Testing
@testable import Versed

struct ReadingScheduleTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        return calendar
    }()

    var schedule: ReadingSchedule { try! ReadingSchedule.loadBundled(calendar: calendar) }

    func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func weeksRunMondayToSundayWithNoGaps() {
        let weeks = schedule.weeks
        // All 52 weeks of 2026 (from Dec 29, 2025) and all 52 weeks of 2027.
        #expect(weeks.count == 52 + 52)
        for week in weeks {
            #expect(calendar.component(.weekday, from: week.start) == 2, "\(week.id) should start on a Monday")
        }
        for (week, next) in zip(weeks, weeks.dropFirst()) {
            #expect(week.end == next.start, "\(week.id) should end where \(next.id) begins")
        }
    }

    @Test func everyPassageExistsInTheScriptures() throws {
        let library = try ScriptureLibrary.loadBundled()
        for week in schedule.weeks {
            for passage in week.passages {
                let items = library.feedItems(for: [passage])
                let verseCount = items.filter { if case .verse = $0 { true } else { false } }.count
                let expected = passage.verses?.count ?? passage.chapters.reduce(0) {
                    $0 + (library.book(id: passage.bookID)?.verses(inChapter: $1).count ?? 0)
                }
                #expect(verseCount > 0 && verseCount == expected, "\(week.id): \(passage.rawValue)")
            }
        }
    }

    @Test func opensToTheWeekContainingToday() {
        #expect(schedule.currentWeek(on: date(2026, 10, 30))?.id == "2026-10-26")
        // Late Sunday night is still the same week.
        #expect(schedule.currentWeek(on: date(2026, 11, 1, hour: 23))?.id == "2026-10-26")
        // Monday starts the next week.
        #expect(schedule.currentWeek(on: date(2026, 11, 2, hour: 0))?.id == "2026-11-02")
        #expect(schedule.currentWeek(on: date(2026, 12, 25))?.label == "Christmas")
    }

    @Test func theNewYearsCourseStartsTheWeekAfterChristmas() {
        #expect(schedule.currentWeek(on: date(2026, 12, 27))?.id == "2026-12-21")
        #expect(schedule.currentWeek(on: date(2026, 12, 28))?.id == "2026-12-28")
        #expect(schedule.currentWeek(on: date(2027, 12, 25))?.id == "2027-12-20")
    }

    @Test func fallsBackWhenTodayIsOutsideTheSchedule() {
        // Before the schedule starts: the first week coming up.
        #expect(schedule.currentWeek(on: date(2025, 6, 1))?.id == "2025-12-29")
        // After it ends: the last week.
        #expect(schedule.currentWeek(on: date(2028, 3, 1))?.id == "2027-12-20")
    }

    @Test func showsShortDates() {
        func dates(_ id: String) -> String? {
            schedule.weeks.first { $0.id == id }?.dateRangeText(calendar: calendar)
        }
        #expect(dates("2026-11-02") == "Nov 2–8")
        #expect(dates("2026-11-30") == "Nov 30 – Dec 6")
        #expect(dates("2026-12-28") == "Dec 28 – Jan 3")
    }

    @Test func chapterRangesStayOnOneLine() {
        let week = schedule.weeks.first { $0.id == "2026-11-02" }!
        #expect(week.label == "Ezekiel 1–3; 33–34; 36–37; 47")
        // A word joiner on each side of every dash keeps "36–37" from splitting across lines.
        #expect(week.displayLabel == "Ezekiel 1\u{2060}–\u{2060}3; 33\u{2060}–\u{2060}34; 36\u{2060}–\u{2060}37; 47")
        // Names without number ranges are left alone.
        #expect(schedule.weeks.first { $0.id == "2026-12-21" }?.displayLabel == "Christmas")
    }

    /// The week with this label, split by book, with the invisible word joiners dropped
    /// so the expectations are easy to read.
    private func books(_ label: String) -> [BookReading] {
        let week = schedule.weeks.first { $0.label == label }!
        let plain = { (text: String) in text.replacingOccurrences(of: "\u{2060}", with: "") }
        return week.readingByBook.map { BookReading(name: plain($0.name), chapters: $0.chapters.map(plain)) }
    }

    @Test func splitsEachBookIntoItsNameAndChapters() {
        #expect(books("Ezekiel 1–3; 33–34; 36–37; 47") == [BookReading(name: "Ezekiel", chapters: ["1–3", "33–34", "36–37", "47"])])
        #expect(books("Jeremiah 31–33; 36–39; Lamentations 1; 3") == [
            BookReading(name: "Jeremiah", chapters: ["31–33", "36–39"]),
            BookReading(name: "Lamentations", chapters: ["1", "3"]),
        ])
        #expect(books("Matthew 21–23; Mark 11; Luke 19–20; John 12").map(\.name) == ["Matthew", "Mark", "Luke", "John"])
    }

    @Test func handlesTrickyBookNames() {
        #expect(books("Joseph Smith—Matthew 1; Matthew 24–25; Mark 12–13; Luke 21").first
            == BookReading(name: "Joseph Smith—Matthew", chapters: ["1"]))
        #expect(books("1 Corinthians 1–7") == [BookReading(name: "1 Corinthians", chapters: ["1–7"])])
        #expect(books("1–3 John; Jude") == [BookReading(name: "1–3 John", chapters: []), BookReading(name: "Jude", chapters: [])])
        #expect(books("1 and 2 Thessalonians") == [BookReading(name: "1 and 2 Thessalonians", chapters: [])])
        #expect(books("Hosea 1–6; 10–14; Joel") == [
            BookReading(name: "Hosea", chapters: ["1–6", "10–14"]),
            BookReading(name: "Joel", chapters: []),
        ])
    }

    @Test func booksReadWholeAndHolidaysHaveNoChapters() {
        #expect(books("Amos; Obadiah; Jonah") == ["Amos", "Obadiah", "Jonah"].map { BookReading(name: $0, chapters: []) })
        #expect(books("Christmas") == [BookReading(name: "Christmas", chapters: [])])
        #expect(books("Easter Week") == [BookReading(name: "Easter Week", chapters: [])])
    }

    /// Every week in every schedule file: putting the books and chapters back together gives
    /// the original reading, and no book name ends in a stray number that should be a chapter.
    @Test func everyWeekSplitsCleanly() {
        for week in schedule.weeks {
            let rebuilt = week.readingByBook
                .map { ([$0.name] + ($0.chapters.isEmpty ? [] : [$0.chapters.joined(separator: "; ")])).joined(separator: " ") }
                .joined(separator: "; ")
                .replacingOccurrences(of: "\u{2060}", with: "")
            #expect(rebuilt == week.label)
            for book in week.readingByBook {
                #expect(book.name.last?.isLetter == true, "\(week.label): \"\(book.name)\"")
            }
        }
    }

    /// Every section on a week's opening card has to jump to the right book and chapter.
    @Test func everySectionStartsOnARealPageOfItsBook() throws {
        let library = try ScriptureLibrary.loadBundled()
        for week in schedule.weeks {
            let pages = library.feedItems(for: week.passages).map { FeedItem.chapterID(of: $0.id) }
            for (book, sections) in zip(week.readingByBook, week.sectionsByBook) {
                #expect(sections.map(\.title) == book.chapters, "\(week.label)")
                for section in sections {
                    #expect(library.book(id: section.start.bookID)?.name == book.name.replacingOccurrences(of: "\u{2060}", with: ""), "\(week.label)")
                    #expect(pages.contains(section.start), "\(week.label): \(section.title)")
                }
            }
        }
        let week = try #require(schedule.weeks.first { $0.label == "Matthew 1; Luke 1" })
        #expect(week.sectionsByBook.flatMap { $0 }.map(\.start.bookID) == ["matt", "luke"])
    }

        @Test func groupsWeeksByCourse() {
        #expect(schedule.weeks.first { $0.id == "2026-12-21" }?.course == "Old Testament 2026")
        // The New Testament year starts the Monday after Christmas 2026.
        #expect(schedule.weeks.first { $0.id == "2026-12-28" }?.course == "New Testament 2027")
    }

    /// Lesson titles belong to the Church's manual, so the schedule files keep only dates, chapters, and links.
    @Test func scheduleFilesHaveNoLessonTitles() throws {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("schedule-") }
        #expect(!urls.isEmpty)
        for url in urls {
            let file = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
            let weeks = file?["weeks"] as? [[String: Any]] ?? []
            #expect(weeks.allSatisfy { $0["title"] == nil }, "\(url.lastPathComponent)")
        }
    }

    @Test func rejectsWeeksThatDontStartOnMonday() {
        let json = #"{"year": 2026, "course": "Test", "manualURL": "https://example.com", "weeks": [{"start": "2026-12-06", "label": "", "readings": []}]}"#
        #expect(throws: ReadingSchedule.LoadError.self) {
            try ReadingSchedule.load(from: Data(json.utf8), calendar: calendar)
        }
    }

    @Test func everyWeekLinksToItsOwnLesson() {
        let links = schedule.weeks.map(\.lessonURL)
        #expect(Set(links).count == links.count, "No two weeks should share a lesson link.")
        for week in schedule.weeks {
            #expect(week.lessonURL.host() == "www.churchofjesuschrist.org", "\(week.id)")
            #expect(week.lessonURL.path().hasPrefix("/study/manual/come-follow-me-"), "\(week.id)")
        }
        // Easter 2027 comes before lesson 13 in the calendar, so its lesson is numbered 14.
        #expect(schedule.currentWeek(on: date(2027, 3, 24))?.lessonURL.lastPathComponent == "14")
    }

    @Test func aWeekWithoutALinkUsesTheManual() throws {
        let json = #"{"year": 2026, "course": "Test", "manualURL": "https://example.com/manual", "weeks": [{"start": "2026-12-07", "label": "", "readings": []}]}"#
        let weeks = try ReadingSchedule.load(from: Data(json.utf8), calendar: calendar)
        #expect(weeks.first?.lessonURL == URL(string: "https://example.com/manual"))
    }
}
