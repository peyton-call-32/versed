import SwiftData
import SwiftUI

/// Every saved verse, newest first. Tap one to read it in context; swipe left to remove it.
struct SavedVersesView: View {
    let library: ScriptureLibrary

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedVerse.savedAt, order: .reverse) private var savedVerses: [SavedVerse]
    /// The verse opened in the feed, if any. Emptying it goes back to the list.
    @Binding var path: [VerseID]

    var body: some View {
        NavigationStack(path: $path) {
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
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
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
        Button {
            path.append(verse.id)
        } label: {
            VStack(spacing: 12) {
                VerseText(verse.text, size: 19, relativeTo: .body)
                    .lineLimit(6)
                    .foregroundStyle(.brand)
                SmallCapsLabel(verse.reference)
            }
            .multilineTextAlignment(.center)
            .padding(18)
            .frame(maxWidth: .infinity)
            .raised(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(verse.reference)
        .accessibilityValue(verse.text)
        .swipeActions {
            Button("Remove", systemImage: "heart.slash", role: .destructive) {
                SavedVerseStore(context: modelContext).unsave(verse.id)
            }
        }
    }
}

#Preview {
    SavedVersesView(library: try! ScriptureLibrary.loadBundled(), path: .constant([]))
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
