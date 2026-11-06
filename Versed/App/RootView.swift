import SwiftUI

/// The app's top-level screen: loads the scriptures and schedule, then shows the tabs.
struct RootView: View {
    @State private var content: Content?
    @AppStorage(Appearance.storageKey) private var appearance: Appearance = .matchPhone
    @AppStorage(IntroView.hasSeenKey) private var hasSeenIntro = false
    @State private var selectedTab = AppTab.today
    @State private var todayPath: [TodayView.Route] = []
    @State private var browsePath: [BrowseView.Route] = []
    @State private var savedPath: [VerseID] = []
    @State private var chrome = ReadingChrome()
    /// The phone's own edges. Hiding the status bar can shrink them on some iPhones, so this keeps the largest.
    @State private var screenInsets = ScreenInsets(top: 0, bottom: 0)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    private struct Content {
        let library: ScriptureLibrary
        let schedule: ReadingSchedule
    }

    /// The intro shows once, the first time the app opens, as soon as the app has loaded.
    private var showsIntro: Binding<Bool> {
        Binding { content != nil && !hasSeenIntro } set: { hasSeenIntro = !$0 }
    }

    /// Goes to Today's list of plans.
    private func showToday() {
        todayPath = []
        selectedTab = .today
    }

    /// Tapping the tab that's already open goes back to its start.
    private func goToStart(of tab: AppTab) {
        switch tab {
        case .today: todayPath = []
        case .browse: browsePath = []
        case .saved: savedPath = []
        }
    }

    var body: some View {
        Group {
            if let content {
                // iOS's tab container keeps each screen's place; our own bar replaces its bar.
                TabView(selection: $selectedTab) {
                    tab(.today) {
                        TodayView(library: content.library, schedule: content.schedule, openBrowse: { selectedTab = .browse }, path: $todayPath)
                    }
                    tab(.browse) {
                        BrowseView(library: content.library, schedule: content.schedule, showToday: { _ in showToday() }, path: $browsePath)
                    }
                    tab(.saved) {
                        SavedVersesView(library: content.library, path: $savedPath)
                    }
                }
                .overlay(alignment: .bottom) {
                    // Animates only the bar, so nothing disturbs a page that's still settling.
                    ZStack {
                        if !chrome.hidesControls {
                            VersedTabBar(selection: $selectedTab, isOnCover: chrome.isOnCover, onReselect: goToStart(of:))
                                // Always solid, so it never leaves a pale band over a navy chapter opening.
                                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                        }
                    }
                    .animation(.easeOut(duration: 0.24), value: chrome.hidesControls)
                }
                // Arriving on a tab keeps the tab bar in view until the reader swipes on.
                .onChange(of: selectedTab) { chrome.reveal() }
                .environment(chrome)
                .environment(\.screenInsets, screenInsets)
                .statusBarHidden(chrome.hidesControls)
            } else {
                ProgressView()
            }
        }
        // On the outer group, so it opens only once the screen below it is fully on display.
        .fullScreenCover(isPresented: showsIntro) {
            IntroView { hasSeenIntro = true }
        }
        .tint(Color.brand)
        .background(Color.appBackground.ignoresSafeArea())
        .onGeometryChange(for: EdgeInsets.self, of: \.safeAreaInsets) { insets in
            screenInsets = ScreenInsets(top: max(screenInsets.top, insets.top), bottom: max(screenInsets.bottom, insets.bottom))
        }
        .windowAppearance(appearance)
        .task {
            let loaded: Content? = await Task.detached {
                guard let library = try? ScriptureLibrary.loadBundled(),
                      let schedule = try? ReadingSchedule.loadBundled()
                else { return nil }
                return Content(library: library, schedule: schedule)
            }.value
            if let loaded {
                prepareSavedPlans(engine: PlanEngine(library: loaded.library, schedule: loaded.schedule))
            }
            content = loaded
        }
    }

    /// Carries earlier weekly reading into a plan, and sets up any plans a UI test asks for.
    private func prepareSavedPlans(engine: PlanEngine) {
        let store = ReadingPlanStore(context: modelContext, engine: engine)
        store.adoptEarlierWeeklyReading()
        guard VersedApp.isUITesting else { return }
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-seed-weekly-plan") {
            store.start(source: .weeklySchedule(course: nil), pace: .week, finish: nil)
        }
        if arguments.contains("-seed-book-plan") {
            let finish = Calendar.current.date(byAdding: .day, value: 56, to: VersedApp.today)
            store.start(source: .volume("bofm"), pace: .day, finish: finish)
        }
    }

    /// One main screen. Lists stop at the bar instead of running under it.
    private func tab<Screen: View>(_ tab: AppTab, @ViewBuilder screen: () -> Screen) -> some View {
        screen()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: VersedTabBar.height)
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(tab)
    }
}

#Preview {
    RootView()
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
