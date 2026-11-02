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
