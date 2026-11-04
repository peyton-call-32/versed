import Foundation
import SwiftData

/// Records which days the reader read and counts their streak.
@MainActor
struct ReadingStreakStore {
    let context: ModelContext
    var calendar: Calendar = .current

    /// Marks `date`'s day as read. Reading more than once in a day keeps one record.
    func recordReading(on date: Date = .now) {
        let key = ReadingDay.key(for: date, calendar: calendar)
        let descriptor = FetchDescriptor<ReadingDay>(predicate: #Predicate { $0.day == key })
        guard (try? context.fetchCount(descriptor)) == 0 else { return }
        context.insert(ReadingDay(day: key))
    }
}

enum ReadingStreak {
    /// The number of days in a row ending today that have a reading.
    ///
    /// If today hasn't been read yet, the streak through yesterday still counts,
    /// so it doesn't drop to zero in the morning before the reader opens the app.
    static func count(readDays: Set<String>, today: Date = .now, calendar: Calendar = .current) -> Int {
        var day = today
        if !readDays.contains(ReadingDay.key(for: day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var count = 0
        while readDays.contains(ReadingDay.key(for: day, calendar: calendar)),
              let previous = calendar.date(byAdding: .day, value: -1, to: day) {
            count += 1
            day = previous
        }
        return count
    }

    /// The longest run of days in a row the reader has ever had.
    static func best(readDays: Set<String>, calendar: Calendar = .current) -> Int {
        var best = 0
        for key in readDays {
            guard var day = ReadingDay.date(forKey: key, calendar: calendar) else { continue }

            // Only count from the first day of each run, so no run is walked twice.
            let isFirstDay = calendar.date(byAdding: .day, value: -1, to: day)
                .map { !readDays.contains(ReadingDay.key(for: $0, calendar: calendar)) } ?? true
            guard isFirstDay else { continue }

            var length = 0
            while readDays.contains(ReadingDay.key(for: day, calendar: calendar)),
                  let next = calendar.date(byAdding: .day, value: 1, to: day) {
                length += 1
                day = next
            }
            best = max(best, length)
        }
        return best
    }
}
