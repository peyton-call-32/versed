import SwiftData
import SwiftUI

/// Every saved verse, newest first. Tap one to read it in context; swipe left to remove it.
struct SavedVersesView: View {
    let library: ScriptureLibrary

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedVerse.savedAt, order: .reverse) private var savedVerses: [SavedVerse]

    var body: some View {
        NavigationStack {
            Group {
                if savedVerses.isEmpty {
                    ContentUnavailableView(
                        "No Saved Verses",
                        systemImage: "heart",
                        description: Text("Double-tap a verse or tap its heart to save it here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                } else {
                    List(savedVerses) { saved in
                        if let id = saved.verse, let verse = library.verse(id) {
                            row(for: verse)
                                .listRowBackground(Color.cardBackground)
                        }
                    }
                    .versedListStyle()
                }
            }
            .navigationTitle("Saved")
            .navigationDestination(for: VerseID.self) { id in
                if let book = library.book(id: id.bookID) {
                    ChapterReadingView(library: library, book: book, startChapter: id.chapter, startItem: FeedItem.id(for: id))
                }
            }
        }
    }

    private func row(for verse: Verse) -> some View {
        NavigationLink(value: verse.id) {
            VStack(alignment: .leading, spacing: 6) {
                Text(verse.text)
                    .font(.system(.body, design: .serif))
                    .lineLimit(3)
                Text(verse.reference)
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
            }
            .padding(.vertical, 4)
        }
        .swipeActions {
            Button("Remove", systemImage: "heart.slash", role: .destructive) {
                SavedVerseStore(context: modelContext).unsave(verse.id)
            }
        }
    }
}

#Preview {
    SavedVersesView(library: try! ScriptureLibrary.loadBundled())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
