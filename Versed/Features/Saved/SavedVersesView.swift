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
                    emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                } else {
                    List(savedVerses) { saved in
                        if let id = saved.verse, let verse = library.verse(id) {
                            row(for: verse)
                                .listRowInsets(EdgeInsets(top: 0, leading: Hardcover.margin, bottom: 0, trailing: Hardcover.margin))
                                .listRowSeparatorTint(Color.hairline)
                                .listRowBackground(Color.clear)
                                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .versedScreen()
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

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart")
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundStyle(.brand)
                .accessibilityHidden(true)
            Text("No Saved Verses")
                .font(.versedTitle(size: 30, relativeTo: .title2))
                .foregroundStyle(.brand)
            Ornament()
            Text("Double-tap a verse or tap its heart to save it here.")
                .font(.versedDetail)
                .foregroundStyle(.secondaryText)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 44)
        .accessibilityElement(children: .combine)
    }

    private func row(for verse: Verse) -> some View {
        Button {
            path.append(verse.id)
        } label: {
            VStack(spacing: 14) {
                VerseText(verse.text, size: 20, relativeTo: .body)
                    .lineSpacing(3)
                    .lineLimit(6)
                    .foregroundStyle(.brand)
                SmallCapsLabel(verse.reference)
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SavedVerseButtonStyle())
        .accessibilityLabel(verse.reference)
        .accessibilityValue(verse.text)
        .swipeActions {
            Button("Remove", systemImage: "heart.slash", role: .destructive) {
                SavedVerseStore(context: modelContext).unsave(verse.id)
            }
            .tint(Color.cover)
        }
    }
}

private struct SavedVerseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pressEffect(configuration.isPressed, scale: 0.98)
    }
}

#Preview {
    SavedVersesView(library: try! ScriptureLibrary.loadBundled(), path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
