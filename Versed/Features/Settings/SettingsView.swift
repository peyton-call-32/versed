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
            ScrollView {
                VStack(spacing: 22) {
                    CardSection(title: "Appearance") {
                        appearancePicker
                    }

                    reminderSection

                    CardSection(title: "Help") {
                        Button {
                            showsIntro = true
                        } label: {
                            CardRowLabel(title: "Show Intro Again")
                        }
                        .buttonStyle(.cardRow)
                    }

                    AboutSection()
                }
                .versedPage()
            }
            .background(Color.appBackground)
            .tint(Color.brand)
            .navigationTitle("Settings")
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

    /// Match Phone, Light, or Dark. The choice is a solid navy pill.
    private var appearancePicker: some View {
        HStack(spacing: 4) {
            ForEach(Appearance.allCases) { option in
                let isSelected = appearance == option
                Button {
                    appearance = option
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color("ProminentButtonLabel") : .brand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isSelected ? Color("ProminentButton") : .clear, in: .rect(cornerRadius: 12))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
    }

    private var reminderSection: some View {
        CardSection(
            title: "Daily Reminder",
            footer: notificationsBlocked
                ? "Notifications for Versed are turned off on this iPhone."
                : "A gentle note once a day. Nothing leaves your phone."
        ) {
            Toggle("Daily reminder", isOn: reminderSwitch)
                .foregroundStyle(.brand)
                .cardRowPadding()

            if reminderIsOn {
                CardDivider()
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    .foregroundStyle(.brand)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            }

            if notificationsBlocked {
                CardDivider()
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    CardRowLabel(title: "Turn On Notifications in iPhone Settings", symbol: CardRowLabel.externalLinkSymbol)
                }
                .buttonStyle(.cardRow)
            }
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
