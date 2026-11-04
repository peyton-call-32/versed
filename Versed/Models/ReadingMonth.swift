import Foundation

/// One month of the streak calendar: its days, and how each one looks given the days read.
struct ReadingMonth: Equatable {
    /// One day on the calendar.
    struct Day: Identifiable, Equatable {
        let date: Date
        let number: Int
        let isToday: Bool
        let isRead: Bool
        /// Whether this day's band connects to the day on its left or right. A band stops at the
        /// end of a calendar row, even when the run of days carries on into the next row.
        let joinsPrevious: Bool
        let joinsNext: Bool

        var id: Date { date }
    }

    /// The first moment of the month.
    let start: Date
    let calendar: Calendar

    init(containing date: Date, calendar: Calendar = .current) {
        self.start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        self.calendar = calendar
    }

    /// "November 2026"
    var title: String {
        start.formatted(Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).month(.wide).year())
    }

    /// The month this many months away.
    func adding(months: Int) -> ReadingMonth {
        ReadingMonth(containing: calendar.date(byAdding: .month, value: months, to: start) ?? start, calendar: calendar)
    }

    /// Empty spaces before the 1st, so it lands under the right weekday.
    var leadingBlanks: Int {
        (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
    }

    /// One letter per weekday, starting on the first day of the week where the reader lives.
    var weekdayLetters: [String] {
        let letters = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(letters[first...] + letters[..<first])
    }

    /// Every day of the month, marked with what the reader has read.
    func days(readDays: Set<String>, today: Date = .now) -> [Day] {
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        let dates = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let isRead = dates.map { readDays.contains(ReadingDay.key(for: $0, calendar: calendar)) }

        return dates.indices.map { index in
            let column = (leadingBlanks + index) % 7
            return Day(
                date: dates[index],
                number: index + 1,
                isToday: calendar.isDate(dates[index], inSameDayAs: today),
                isRead: isRead[index],
                joinsPrevious: isRead[index] && column > 0 && index > 0 && isRead[index - 1],
                joinsNext: isRead[index] && column < 6 && index + 1 < count && isRead[index + 1]
            )
        }
    }
}
