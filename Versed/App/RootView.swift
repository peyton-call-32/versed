import SwiftUI

/// The app's top-level screen: loads the scriptures and schedule, then shows the tabs.
struct RootView: View {
    @State private var content: Content?
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .matchPhone
    @AppStorage(IntroView.hasSeenKey) private var hasSeenIntro = false
    @State private var selectedTab = AppTab.thisWeek
    /// The week shown on the This Week tab, or `nil` for this week.
    @State private var selectedWeekID: ReadingWeek.ID?
    @State private var weekNavigation = FeedNavigation()
    @State private var browsePath: [BrowseView.Route] = []
    @State private var savedPath: [VerseID] = []

    private struct Content {
        let library: ScriptureLibrary
        let schedule: ReadingSchedule
    }

    /// The intro shows once, the first time the app opens, as soon as the app has loaded.
    private var showsIntro: Binding<Bool> {
        Binding { content != nil && !hasSeenIntro } set: { hasSeenIntro = !$0 }
    }

    /// Shows a week's reading on the This Week tab: `nil` for this week, or any week from the schedule.
    private func openWeek(_ weekID: ReadingWeek.ID?) {
        selectedWeekID = weekID
        selectedTab = .thisWeek
    }

    /// Tapping the tab that's already open goes back to its start.
    private func goToStart(of tab: AppTab) {
        switch tab {
        case .thisWeek: weekNavigation.goToStart()
        case .browse: browsePath = []
        case .saved: savedPath = []
        }
    }

    var body: some View {
        Group {
            if let content {
                // iOS's tab container keeps each screen's place; our own bar replaces its bar.
                TabView(selection: $selectedTab) {
                    tab(.thisWeek) {
                        WeeklyReadingView(library: content.library, schedule: content.schedule, navigation: weekNavigation, selectedWeekID: $selectedWeekID)
                    }
                    tab(.browse) {
                        BrowseView(library: content.library, schedule: content.schedule, openWeek: openWeek, path: $browsePath)
                    }
                    tab(.saved) {
                        SavedVersesView(library: content.library, path: $savedPath)
                    }
                }
                .overlay(alignment: .bottom) {
                    FloatingTabBar(selection: $selectedTab, onReselect: goToStart(of:))
                }
            } else {
                ProgressView()
            }
        }
        // On the outer group, so it opens only once the screen below it is fully on display.
        .fullScreenCover(isPresented: showsIntro) {
            IntroView { hasSeenIntro = true }
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

    /// One main screen. Lists stop short of the floating bar, while the bar still floats over them as they scroll.
    private func tab<Screen: View>(_ tab: AppTab, @ViewBuilder screen: () -> Screen) -> some View {
        screen()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: FloatingTabBar.height)
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(tab)
    }
}

#Preview {
    RootView()
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
