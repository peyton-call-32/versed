import SwiftUI

/// The app's top-level screen: loads the scriptures and schedule, then shows the tabs.
struct RootView: View {
    @State private var content: Content?
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .matchPhone
    @AppStorage(IntroView.hasSeenKey) private var hasSeenIntro = false
    @State private var selectedTab = Tab.thisWeek
    /// The week shown on the This Week tab, or `nil` for this week.
    @State private var selectedWeekID: ReadingWeek.ID?

    enum Tab: Hashable {
        case thisWeek, browse, saved
    }

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
                TabView(selection: $selectedTab) {
                    WeeklyReadingView(library: content.library, schedule: content.schedule, selectedWeekID: $selectedWeekID)
                        .tabItem { Label("This Week", systemImage: "calendar") }
                        .tag(Tab.thisWeek)

                    BrowseView(library: content.library, schedule: content.schedule, openWeek: openWeek)
                        .tabItem { Label("Browse", systemImage: "books.vertical") }
                        .tag(Tab.browse)

                    SavedVersesView(library: content.library)
                        .tabItem { Label("Saved", systemImage: "heart") }
                        .tag(Tab.saved)
                }
                .fullScreenCover(isPresented: showsIntro) {
                    IntroView { hasSeenIntro = true }
                }
            } else {
                ProgressView()
            }
        }
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
}

#Preview {
    RootView()
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
