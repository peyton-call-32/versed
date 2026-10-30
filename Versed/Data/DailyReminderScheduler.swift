import UserNotifications

/// Schedules and cancels the daily reminder with iOS. Everything happens on the phone.
@MainActor
struct DailyReminderScheduler {
    private var center: UNUserNotificationCenter { .current() }

    /// Asks for notification permission (iOS only shows the prompt the first time),
    /// then schedules the reminder. Returns `false` if notifications aren't allowed.
    func turnOn(minuteOfDay: Int) async -> Bool {
        let allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard allowed else { return false }
        await schedule(minuteOfDay: minuteOfDay)
        return true
    }

    /// Replaces any scheduled reminder with one that repeats daily at `minuteOfDay`.
    func schedule(minuteOfDay: Int) async {
        let content = UNMutableNotificationContent()
        content.title = DailyReminder.title
        content.body = DailyReminder.body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DailyReminder.triggerTime(minuteOfDay: minuteOfDay),
            repeats: true
        )
        let request = UNNotificationRequest(identifier: DailyReminder.notificationID, content: content, trigger: trigger)

        turnOff()
        try? await center.add(request)
    }

    func turnOff() {
        center.removePendingNotificationRequests(withIdentifiers: [DailyReminder.notificationID])
    }

    /// Whether notifications for Versed are allowed in the iPhone's Settings app.
    func notificationsAllowed() async -> Bool {
        await center.notificationSettings().authorizationStatus == .authorized
    }
}
