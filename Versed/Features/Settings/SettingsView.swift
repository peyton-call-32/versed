import SwiftUI
import UIKit

/// App settings, opened from the gear button on the Browse tab.
struct SettingsView: View {
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .matchPhone
    @AppStorage(DailyReminder.isOnKey) private var reminderIsOn = false
    @AppStorage(DailyReminder.minuteOfDayKey) private var reminderMinuteOfDay = DailyReminder.defaultMinuteOfDay
    /// Shown when the reader wants the reminder but iOS notifications are off for Versed.
    @State private var notificationsBlocked = false
    @State private var showsIntro = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let scheduler = DailyReminderScheduler()

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                reminderSection

                Section("Help") {
                    Button("Show Intro Again") { showsIntro = true }
                }

                AboutSection()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showsIntro) {
                IntroView { showsIntro = false }
            }
            .task {
                if reminderIsOn {
                    notificationsBlocked = await !scheduler.notificationsAllowed()
                }
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Daily reminder", isOn: reminderSwitch)

            if reminderIsOn {
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
            }

            if notificationsBlocked {
                Button("Turn On Notifications in iPhone Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
            }
        } header: {
            Text("Daily Reminder")
        } footer: {
            Text(notificationsBlocked
                 ? "Notifications for Versed are turned off on this iPhone."
                 : "A gentle note once a day. Nothing leaves your phone.")
                .foregroundStyle(.secondaryText)
        }
    }

    /// The on/off switch. Turning it on asks iOS for permission and schedules the reminder.
    private var reminderSwitch: Binding<Bool> {
        Binding {
            reminderIsOn
        } set: { isOn in
            reminderIsOn = isOn
            Task { await reminderSwitched(on: isOn) }
        }
    }

    /// The reminder time as a `Date` for the time picker. Changing it reschedules the reminder.
    private var reminderTime: Binding<Date> {
        Binding {
            DailyReminder.date(minuteOfDay: reminderMinuteOfDay)
        } set: { date in
            reminderMinuteOfDay = DailyReminder.minuteOfDay(from: date)
            Task { await scheduler.schedule(minuteOfDay: reminderMinuteOfDay) }
        }
    }

    private func reminderSwitched(on isOn: Bool) async {
        guard isOn else {
            scheduler.turnOff()
            notificationsBlocked = false
            return
        }
        let scheduled = await scheduler.turnOn(minuteOfDay: reminderMinuteOfDay)
        notificationsBlocked = !scheduled
        if !scheduled {
            reminderIsOn = false
        }
    }
}

#Preview {
    SettingsView()
}
