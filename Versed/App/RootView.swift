import SwiftUI

/// The app's top-level screen: loads the scriptures, then shows the feed.
struct RootView: View {
    @State private var library: ScriptureLibrary?

    /// Temporary sample reading until the weekly schedule is added.
    private let sampleChapters = [
        ChapterID(bookID: "jer", chapter: 31),
        ChapterID(bookID: "jer", chapter: 32),
    ]

    var body: some View {
        Group {
            if let library {
                FeedView(items: library.feedItems(for: sampleChapters))
            } else {
                ProgressView()
            }
        }
        .task {
            library = await Task.detached { try? ScriptureLibrary.loadBundled() }.value
        }
    }
}

#Preview {
    RootView()
}
