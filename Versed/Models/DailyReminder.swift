import Foundation

/// The optional once-a-day notification. It's off until the reader turns it on in Settings.
///
/// Only the on/off choice and the time are stored, on the phone. The wording stays the same
/// every day and never mentions the reading streak.
enum DailyReminder {
    /// The `@AppStorage` key for whether the reminder is on.
    static let isOnKey = "dailyReminderIsOn"
    /// The `@AppStorage` key for the reminder time, in minutes after midnight.
    static let minuteOfDayKey = "dailyReminderMinuteOfDay"

    /// 8:00 AM.
    static let defaultMinuteOfDay = 8 * 60

    static let notificationID = "daily-reminder"
    static let title = "Versed"
    static let body = "Today's verse is ready."

    /// The hour and minute the notification repeats at, e.g. 8:30 PM for 1230.
    static func triggerTime(minuteOfDay: Int) -> DateComponents {
        DateComponents(hour: minuteOfDay / 60, minute: minuteOfDay % 60)
    }

    /// `minuteOfDay` as a time on `day`, for showing in a time picker.
    static func date(minuteOfDay: Int, on day: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: minuteOfDay / 60, minute: minuteOfDay % 60, second: 0, of: day) ?? day
    }

    /// The minutes after midnight of `date`'s time, ignoring the day.
    static func minuteOfDay(from date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}
