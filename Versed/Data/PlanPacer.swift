import Foundation

/// Splits chapters into readings. Readings always end at the end of a chapter, and a long chapter
/// counts for more than a short one, so the days come out about even.
enum PlanPacer {
    /// How many of the next chapters to read in the first of the remaining periods.
    ///
    /// - Parameters:
    ///   - weights: How long each remaining chapter is, in verses.
    ///   - lengths: How long each remaining period is, in days. A short first week gets a smaller share.
    static func nextCount(weights: some Collection<Int>, lengths: some Collection<Int>) -> Int {
        guard let first = lengths.first, !weights.isEmpty else { return 0 }
        guard lengths.count > 1 else { return weights.count }

        let target = Double(weights.reduce(0, +)) * Double(first) / Double(lengths.reduce(0, +))
        var taken = 0
        var total = 0
        for weight in weights {
            // Stops at whichever chapter end lands closest to an even share, always reading at least one.
            let isCloserToStop = taken > 0 && Double(total + weight) - target > target - Double(total)
            if isCloserToStop { break }
            total += weight
            taken += 1
        }
        return taken
    }

    /// Every reading from the start, in order. Runs out early when there are fewer chapters than periods.
    static func chunks(weights: [Int], lengths: [Int]) -> [Range<Int>] {
        var result: [Range<Int>] = []
        var start = 0
        var remaining = lengths[...]
        while start < weights.count, !remaining.isEmpty {
            let count = nextCount(weights: weights[start...], lengths: remaining)
            result.append(start..<start + count)
            start += count
            remaining = remaining.dropFirst()
        }
        return result
    }
}

/// Days and weeks for pacing. Weeks run Monday through Sunday, like the rest of the app.
struct PlanCalendar: Sendable {
    var calendar: Calendar = .current

    /// One day or week of a plan.
    struct Period: Hashable, Sendable {
        let start: Date
        /// How many of the plan's days fall in this period.
        let length: Int
    }

    func days(from start: Date, to end: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
    }

    func monday(of date: Date) -> Date {
        let day = calendar.startOfDay(for: date)
        // Sunday is 1 and Monday is 2 in the Gregorian calendar.
        let sinceMonday = (calendar.component(.weekday, from: day) + 5) % 7
        return calendar.date(byAdding: .day, value: -sinceMonday, to: day) ?? day
    }

    func periodKey(for date: Date, pace: PlanPace) -> String {
        ReadingDay.key(for: pace == .day ? date : monday(of: date), calendar: calendar)
    }

    /// Every period from `start` through `finish`. The first and last weeks can be short.
    func periods(from start: Date, through finish: Date, pace: PlanPace) -> [Period] {
        let first = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: finish)
        guard first <= last else { return [Period(start: first, length: 1)] }

        var result: [Period] = []
        var cursor = first
        while cursor <= last {
            let next: Date
            switch pace {
            case .day: next = calendar.date(byAdding: .day, value: 1, to: cursor) ?? last
            case .week: next = calendar.date(byAdding: .day, value: 7, to: monday(of: cursor)) ?? last
            }
            let end = min(next, calendar.date(byAdding: .day, value: 1, to: last) ?? next)
            result.append(Period(start: cursor, length: max(days(from: cursor, to: end), 1)))
            cursor = next
        }
        return result
    }

    /// "Nov 5", with the year added when it isn't this year's.
    func shortDate(_ date: Date, relativeTo today: Date) -> String {
        var style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.abbreviated).day()
        if calendar.component(.year, from: date) != calendar.component(.year, from: today) {
            style = style.year()
        }
        return date.formatted(style)
    }
}
