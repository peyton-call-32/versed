import SwiftUI

/// The app's top-level screen: loads the scriptures and schedule, then shows this week's reading.
struct RootView: View {
    @State private var content: Content?

    private struct Content {
        let library: ScriptureLibrary
        let schedule: ReadingSchedule
    }

    var body: some View {
        Group {
            if let content {
                WeeklyReadingView(library: content.library, schedule: content.schedule)
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
}
