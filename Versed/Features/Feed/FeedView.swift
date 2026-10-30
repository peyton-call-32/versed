import SwiftData
import SwiftUI

/// A full-screen, swipe-up feed with one verse per page.
struct FeedView: View {
    let items: [FeedItem]

    @Environment(\.modelContext) private var modelContext
    @Query private var savedVerses: [SavedVerse]

    /// The ID of the page currently on screen.
    @State private var currentItemID: FeedItem.ID?

    /// - Parameter itemID: The page to open on, or `nil` for the first page.
    init(items: [FeedItem], startingAt itemID: FeedItem.ID? = nil) {
        self.items = items
        _currentItemID = State(initialValue: itemID)
    }

    var body: some View {
        let savedIDs = Set(savedVerses.map(\.verseID))

        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    page(for: item, savedIDs: savedIDs)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .overlay(alignment: .bottom) {
                            if item.id == items.first?.id {
                                swipeHint
                            }
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentItemID)
        .scrollIndicators(.hidden)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func page(for item: FeedItem, savedIDs: Set<String>) -> some View {
        switch item {
        case .weekIntro(let week):
            WeekIntroCard(week: week)
        case .chapterTitle(let title):
            ChapterTitleCard(title: title)
        case .verse(let verse):
            let store = SavedVerseStore(context: modelContext)
            VerseCard(
                verse: verse,
                isSaved: savedIDs.contains(verse.id.rawValue),
                onDoubleTap: { store.save(verse.id) },
                onHeartTap: { store.toggle(verse.id) }
            )
        }
    }

    private var swipeHint: some View {
        Label("Swipe up to read", systemImage: "chevron.up")
            .font(.footnote)
            .foregroundStyle(.secondary)
            // Clears the tab bar, which floats over the bottom of the feed.
            .padding(.bottom, 120)
    }
}

#Preview {
    let library = try! ScriptureLibrary.loadBundled()
    FeedView(items: library.feedItems(for: [Passage(bookID: "1-ne", chapters: 3...3)]))
        .modelContainer(for: SavedVerse.self, inMemory: true)
}
