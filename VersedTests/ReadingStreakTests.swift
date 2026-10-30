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
