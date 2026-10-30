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
        // 2026 (Oct 26–Dec 27) plus all 52 weeks of 2027.
        #expect(weeks.count == 9 + 52)
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
        #expect(schedule.currentWeek(on: date(2026, 12, 25))?.title == "We Have Waited for Him, and He Will Save Us")
    }

    @Test func theNewYearsCourseStartsTheWeekAfterChristmas() {
        #expect(schedule.currentWeek(on: date(2026, 12, 27))?.id == "2026-12-21")
        #expect(schedule.currentWeek(on: date(2026, 12, 28))?.id == "2026-12-28")
        #expect(schedule.currentWeek(on: date(2027, 12, 25))?.id == "2027-12-20")
    }

    @Test func fallsBackWhenTodayIsOutsideTheSchedule() {
        // Before the schedule starts: the first week coming up.
        #expect(schedule.currentWeek(on: date(2026, 1, 1))?.id == "2026-10-26")
        // After it ends: the last week.
        #expect(schedule.currentWeek(on: date(2028, 3, 1))?.id == "2027-12-20")
    }

    @Test func rejectsWeeksThatDontStartOnMonday() {
        let json = #"{"year": 2026, "course": "Test", "manualURL": "https://example.com", "weeks": [{"start": "2026-12-06", "title": "", "label": "", "readings": []}]}"#
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
        let json = #"{"year": 2026, "course": "Test", "manualURL": "https://example.com/manual", "weeks": [{"start": "2026-12-07", "title": "", "label": "", "readings": []}]}"#
        let weeks = try ReadingSchedule.load(from: Data(json.utf8), calendar: calendar)
        #expect(weeks.first?.lessonURL == URL(string: "https://example.com/manual"))
    }
}
