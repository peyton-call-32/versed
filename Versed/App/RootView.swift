import SwiftUI

/// The app's top-level screen. Placeholder until the feed is built.
struct RootView: View {
    @State private var library: ScriptureLibrary?

    private let sampleVerseID = VerseID(bookID: "1-ne", chapter: 3, verse: 7)

    var body: some View {
        VStack(spacing: 24) {
            Text("Versed")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))

            if let library {
                Text("\(library.verseCount.formatted()) verses loaded")
                    .foregroundStyle(.secondary)

                if let verse = library.verse(sampleVerseID) {
                    VStack(spacing: 12) {
                        Text(verse.text)
                            .font(.system(.title3, design: .serif))
                        Text(verse.reference)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
            } else {
                ProgressView()
            }
        }
        .padding(32)
        .task {
            library = await Task.detached { try? ScriptureLibrary.loadBundled() }.value
        }
    }
}

#Preview {
    RootView()
}
