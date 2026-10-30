import SwiftUI

/// The app's top-level screen: loads the scriptures and schedule, then shows the tabs.
struct RootView: View {
    @State private var content: Content?

    private struct Content {
        let library: ScriptureLibrary
        let schedule: ReadingSchedule
    }

    var body: some View {
        Group {
            if let content {
                TabView {
                    WeeklyReadingView(library: content.library, schedule: content.schedule)
                        .tabItem { Label("This Week", systemImage: "calendar") }

                    BrowseView(library: content.library)
                        .tabItem { Label("Browse", systemImage: "books.vertical") }

                    SavedVersesView(library: content.library)
                        .tabItem { Label("Saved", systemImage: "heart") }
                }
            } else {
                ProgressView()
            }
        }
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
        .modelContainer(for: SavedVerse.self, inMemory: true)
}
