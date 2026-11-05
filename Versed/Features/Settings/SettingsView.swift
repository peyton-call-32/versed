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
    @Environment(\.dynamicTypeSize) private var typeSize

    private let scheduler = DailyReminderScheduler()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    LedgerSection(title: "Appearance") {
                        appearancePicker
                    }

                    reminderSection

                    LedgerSection(title: "Help") {
                        Button {
                            showsIntro = true
                        } label: {
                            LedgerRowLabel(title: "Show Intro Again")
                        }
                        .buttonStyle(.ledgerRow)
                    }

                    AboutSection()
                }
                .versedPage()
            }
            .versedScreen()
            .tint(Color.brand)
            .navigationTitle("Settings")
            .toolbar {
                DoneToolbarItem { dismiss() }
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

    /// Match Phone, Light, or Dark. The choice is a solid navy block.
    private var appearancePicker: some View {
        // Stacked at the largest text sizes, so "Match Phone" never breaks in the middle.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 4))
        return layout {
            ForEach(Appearance.allCases) { option in
                let isSelected = appearance == option
                Button {
                    appearance = option
                } label: {
                    Text(option.label)
                        .font(.versedDetail)
                        .foregroundStyle(isSelected ? Color("ProminentButtonLabel") : .brand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(isSelected ? Color("ProminentButton") : .clear, in: Hardcover.corner)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }

    private var reminderSection: some View {
        LedgerSection(
            title: "Daily Reminder",
            footer: notificationsBlocked
                ? "Notifications for Versed are turned off on this iPhone."
                : "A gentle note once a day. Nothing leaves your phone."
        ) {
            Toggle("Daily reminder", isOn: reminderSwitch)
                .font(.versedRow)
                .foregroundStyle(.brand)
                .ledgerRowPadding()

            if reminderIsOn {
                LedgerRule()
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    .font(.versedRow)
                    .foregroundStyle(.brand)
                    .padding(.vertical, 6)
            }

            if notificationsBlocked {
                LedgerRule()
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    LedgerRowLabel(title: "Turn On Notifications in iPhone Settings", symbol: LedgerRowLabel.externalLinkSymbol)
                }
                .buttonStyle(.ledgerRow)
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
