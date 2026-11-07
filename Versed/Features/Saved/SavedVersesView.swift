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
                    .background { PaperSurface() }
                } else {
                    List(savedVerses) { saved in
                        if let id = saved.verse, let verse = library.verse(id) {
                            row(for: verse)
                                .listRowInsets(EdgeInsets(top: 0, leading: Hardcover.margin, bottom: 0, trailing: Hardcover.margin))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
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

    private var lastVerseID: VerseID? { savedVerses.last?.verse }

    private var emptyState: some View {
        VStack(spacing: 14) {
            GlyphView(.heart, size: 34, lineWidth: 1)
                .foregroundStyle(.brand)
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
                // A printer's break between one saved verse and the next.
                if verse.id != lastVerseID {
                    Ornament(lineLength: 22)
                        .padding(.top, 22)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, 26)
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
