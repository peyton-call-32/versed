import Foundation

/// One week of the Come, Follow Me schedule. Weeks run Monday through Sunday.
struct ReadingWeek: Identifiable, Hashable, Sendable {
    /// The Monday the week starts, as "yyyy-MM-dd". Stays the same forever, so it's safe to save.
    let id: String
    /// Midnight at the start of Monday.
    let start: Date
    /// Midnight at the start of the following Monday.
    let end: Date
    let title: String
    /// The reading as the schedule prints it, such as "Daniel 1–7".
    let label: String
    let passages: [Passage]

    func contains(_ date: Date) -> Bool {
        start <= date && date < end
    }

    /// "Oct 26 – Nov 1"
    var dateRangeText: String {
        let lastDay = end.addingTimeInterval(-1)
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(start.formatted(style)) – \(lastDay.formatted(style))"
    }
}
