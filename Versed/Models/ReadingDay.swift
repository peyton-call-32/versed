import Foundation
import SwiftData

/// A day the reader read at least one verse, stored on the phone for the reading streak.
///
/// Only the date is stored, never what was read.
@Model
final class ReadingDay {
    /// The day in the reader's calendar, as "yyyy-MM-dd".
    @Attribute(.unique) var day: String

    init(day: String) {
        self.day = day
    }

    /// "2026-10-30" for any time on October 30, 2026 in `calendar`'s time zone.
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
