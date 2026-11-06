import SwiftData
import SwiftUI
import UIKit

/// App settings, the last tab.
struct SettingsView: View {
    let engine: PlanEngine
    @Binding var path: [Route]

    /// The screens this tab can open.
    enum Route: Hashable {
        case reorderPlans
    }

    @Query private var plans: [ReadingPlan]
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .matchPhone
    @AppStorage(DailyReminder.isOnKey) private var reminderIsOn = false
    @AppStorage(DailyReminder.minuteOfDayKey) private var reminderMinuteOfDay = DailyReminder.defaultMinuteOfDay
    /// Shown when the reader wants the reminder but iOS notifications are off for Versed.
    @State private var notificationsBlocked = false
    @State private var showsIntro = false
    @Environment(\.openURL) private var openURL

    private let scheduler = DailyReminderScheduler()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 22) {
                    // Only once there's more than one plan to put in order.
                    if plans.count > 1 {
                        LedgerSection(title: "Plans") {
                            NavigationLink(value: Route.reorderPlans) {
                                LedgerRowLabel(title: "Reorder Plans")
                            }
                            .buttonStyle(.ledgerRow)
                        }
                    }

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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .reorderPlans: ReorderPlansView(engine: engine)
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

    /// Match Phone, Light, or Dark.
    private var appearancePicker: some View {
        BlockPicker(options: Appearance.allCases, selection: $appearance) { $0.label }
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
    SettingsView(engine: PlanEngine(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled()), path: .constant([]))
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
