import Foundation

/// The Come, Follow Me weekly reading schedule, loaded from `Resources/Schedules`.
///
/// Each year is its own file named `schedule-YYYY.json`. To add a year, drop in a new file
/// and rerun `xcodegen`; every schedule file in the app is loaded automatically.
struct ReadingSchedule: Sendable {
    /// All weeks from every year, earliest first.
    let weeks: [ReadingWeek]

    init(weeks: [ReadingWeek]) {
        self.weeks = weeks.sorted { $0.start < $1.start }
    }

    /// The week to open the app to: the week containing `date`, or else the next week coming up,
    /// or else the most recent week.
    func currentWeek(on date: Date = .now) -> ReadingWeek? {
        weeks.first { $0.contains(date) }
            ?? weeks.first { $0.start > date }
            ?? weeks.last
    }

    // MARK: - Loading

    static func loadBundled(from bundle: Bundle = .main, calendar: Calendar = .current) throws -> ReadingSchedule {
        let urls = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("schedule-") }
        let weeks = try urls.flatMap { try load(from: Data(contentsOf: $0), calendar: calendar) }
        return ReadingSchedule(weeks: weeks)
    }

    static func load(from data: Data, calendar: Calendar) throws -> [ReadingWeek] {
        let file = try JSONDecoder().decode(ScheduleFile.self, from: data)
        return try file.weeks.map { week in
            guard let start = date(from: week.start, calendar: calendar),
                  calendar.component(.weekday, from: start) == 2,
                  let end = calendar.date(byAdding: .day, value: 7, to: start)
            else { throw LoadError.invalidStartDate(week.start) }

            return ReadingWeek(
                id: week.start,
                start: start,
                end: end,
                title: week.title,
                label: week.label,
                passages: week.readings
            )
        }
    }

    /// Reads "2026-10-26" as midnight on that day in the given calendar's time zone.
    private static func date(from text: String, calendar: Calendar) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// The layout of a `schedule-YYYY.json` file.
    private struct ScheduleFile: Decodable {
        struct Week: Decodable {
            let start: String
            let title: String
            let label: String
            let readings: [Passage]
        }

        let year: Int
        let course: String
        let weeks: [Week]
    }

    enum LoadError: Error {
        /// The start date is unreadable or isn't a Monday.
        case invalidStartDate(String)
    }
}
