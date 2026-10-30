import Foundation
import Testing
@testable import Versed

struct DailyReminderTests {
    let calendar = Calendar(identifier: .gregorian)

    @Test func isOffAndAtEightByDefault() {
        #expect(DailyReminder.defaultMinuteOfDay == 8 * 60)
    }

    @Test func triggerRepeatsAtTheChosenHourAndMinute() {
        let time = DailyReminder.triggerTime(minuteOfDay: 20 * 60 + 30)
        #expect(time.hour == 20)
        #expect(time.minute == 30)
        #expect(time.day == nil)
    }

    @Test func timeSurvivesTheRoundTripThroughThePicker() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30))!
        for minute in [0, 7 * 60 + 15, 12 * 60, 23 * 60 + 59] {
            let date = DailyReminder.date(minuteOfDay: minute, on: day, calendar: calendar)
            #expect(DailyReminder.minuteOfDay(from: date, calendar: calendar) == minute)
        }
    }

    @Test func wordingNeverMentionsTheStreak() {
        let text = (DailyReminder.title + " " + DailyReminder.body).lowercased()
        for word in ["streak", "miss", "don't", "lose", "broke"] {
            #expect(!text.contains(word))
        }
    }
}
