import Foundation
import SwiftData
import Testing
@testable import Versed

struct ReadingStreakTests {
    let calendar = Calendar(identifier: .gregorian)
    /// Noon on Friday, October 30, 2026.
    var today: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 12))! }

    func count(_ days: [String]) -> Int {
        ReadingStreak.count(readDays: Set(days), today: today, calendar: calendar)
    }

    @Test func noReadingMeansNoStreak() {
        #expect(count([]) == 0)
    }

    @Test func countsDaysInARowEndingToday() {
        #expect(count(["2026-10-28", "2026-10-29", "2026-10-30"]) == 3)
    }

    @Test func streakThroughYesterdayLastsUntilTheEndOfToday() {
        #expect(count(["2026-10-28", "2026-10-29"]) == 2)
    }

    @Test func aMissedDayEndsTheStreak() {
        #expect(count(["2026-10-27", "2026-10-29", "2026-10-30"]) == 2)
        #expect(count(["2026-10-27", "2026-10-28"]) == 0)
    }

    @Test func streakContinuesAcrossMonths() {
        let days = ["2026-09-30"] + (1...30).map { String(format: "2026-10-%02d", $0) }
        #expect(count(days) == 31)
    }

    @Test func dayKeyIsZeroPadded() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 23))!
        #expect(ReadingDay.key(for: date, calendar: calendar) == "2026-03-05")
    }
}

struct BestStreakTests {
    let calendar = Calendar(identifier: .gregorian)

    @Test func noReadingMeansNoBestStreak() {
        #expect(ReadingStreak.best(readDays: [], calendar: calendar) == 0)
    }

    @Test func findsTheLongestRunAnywhere() {
        let days: Set = ["2026-01-01", "2026-03-10", "2026-03-11", "2026-03-12", "2026-10-29", "2026-10-30"]
        #expect(ReadingStreak.best(readDays: days, calendar: calendar) == 3)
    }

    @Test func runsCarryAcrossMonthsAndYears() {
        let days: Set = ["2026-12-30", "2026-12-31", "2027-01-01"]
        #expect(ReadingStreak.best(readDays: days, calendar: calendar) == 3)
    }
}

struct ReadingMonthTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }()

    func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func laysOutTheMonthUnderTheRightWeekdays() {
        // November 2026 starts on a Sunday; October 2026 starts on a Thursday.
        let november = ReadingMonth(containing: date(2026, 11, 4), calendar: calendar)
        #expect(november.leadingBlanks == 0)
        #expect(november.days(readDays: []).count == 30)
        #expect(november.adding(months: -1).leadingBlanks == 4)
        #expect(november.adding(months: -1).days(readDays: []).count == 31)
    }

    @Test func weeksCanStartOnMonday() {
        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2
        let november = ReadingMonth(containing: date(2026, 11, 4), calendar: mondayFirst)
        #expect(november.leadingBlanks == 6)
        #expect(november.weekdayLetters.first == "M")
    }

    @Test func marksReadDaysAndToday() {
        let month = ReadingMonth(containing: date(2026, 11, 4), calendar: calendar)
        let days = month.days(readDays: ["2026-11-03"], today: date(2026, 11, 4))
        #expect(days[2].isRead)
        #expect(!days[3].isRead)
        #expect(days[3].isToday)
        #expect(!days[2].isToday)
    }

    @Test func daysInARowJoinButOnlyWithinARow() {
        // Nov 7 is a Saturday and Nov 8 a Sunday, so that pair sits on two different rows.
        let month = ReadingMonth(containing: date(2026, 11, 4), calendar: calendar)
        let keys = (6...9).map { String(format: "2026-11-%02d", $0) }
        let days = month.days(readDays: Set(keys))

        #expect(!days[5].joinsPrevious && days[5].joinsNext) // the 6th starts a band
        #expect(days[6].joinsPrevious && !days[6].joinsNext) // the 7th ends its row
        #expect(!days[7].joinsPrevious && days[7].joinsNext) // the 8th starts the next row
        #expect(days[8].joinsPrevious && !days[8].joinsNext) // the 9th ends the band
        #expect(!days[9].joinsPrevious)
    }
}

@MainActor
struct ReadingStreakStoreTests {
    let container = try! ModelContainer(for: ReadingDay.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    @Test func readingTwiceInADayKeepsOneRecord() throws {
        let store = ReadingStreakStore(context: container.mainContext)
        store.recordReading()
        store.recordReading()
        #expect(try container.mainContext.fetchCount(FetchDescriptor<ReadingDay>()) == 1)
    }
}
