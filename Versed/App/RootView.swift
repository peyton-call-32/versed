import SwiftUI

/// The app's top-level screen: loads the scriptures and schedule, then shows the tabs.
struct RootView: View {
    @State private var content: Content?
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .matchPhone
    @AppStorage(IntroView.hasSeenKey) private var hasSeenIntro = false
    @State private var selectedTab = AppTab.thisWeek
    /// The week shown on the This Week tab, or `nil` for this week.
    @State private var selectedWeekID: ReadingWeek.ID?

    private struct Content {
        let library: ScriptureLibrary
        let schedule: ReadingSchedule
    }

    /// The intro shows once, the first time the app opens.
    private var showsIntro: Binding<Bool> {
        Binding { !hasSeenIntro } set: { hasSeenIntro = !$0 }
    }

    /// Shows a week's reading on the This Week tab: `nil` for this week, or any week from the schedule.
    private func openWeek(_ weekID: ReadingWeek.ID?) {
        selectedWeekID = weekID
        selectedTab = .thisWeek
    }

    var body: some View {
        Group {
            if let content {
                // All three stay alive behind the bar, so each keeps its place when you switch away.
                ZStack {
                    tab(.thisWeek) {
                        WeeklyReadingView(library: content.library, schedule: content.schedule, selectedWeekID: $selectedWeekID)
                    }
                    tab(.browse) {
                        BrowseView(library: content.library, schedule: content.schedule, openWeek: openWeek)
                    }
                    tab(.saved) {
                        SavedVersesView(library: content.library)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    FloatingTabBar(selection: $selectedTab)
                }
                .fullScreenCover(isPresented: showsIntro) {
                    IntroView { hasSeenIntro = true }
                }
            } else {
                ProgressView()
            }
        }
        .tint(Color.brand)
        .windowAppearance(appearance)
        .task {
            content = await Task.detached {
                guard let library = try? ScriptureLibrary.loadBundled(),
                      let schedule = try? ReadingSchedule.loadBundled()
                else { return nil }
                return Content(library: library, schedule: schedule)
            }.value
        }
    }

    /// One main screen. Only the selected one can be seen, tapped, or read by VoiceOver.
    private func tab<Screen: View>(_ tab: AppTab, @ViewBuilder screen: () -> Screen) -> some View {
        let isSelected = selectedTab == tab
        return screen()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
    }
}

#Preview {
    RootView()
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
