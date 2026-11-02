import SwiftData
import SwiftUI

/// A full-screen, swipe-up feed with one verse per page.
struct FeedView: View {
    let items: [FeedItem]
    /// Called with the opening page, then with each page the reader swipes to.
    let onPageChange: (FeedItem.ID) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var savedVerses: [SavedVerse]

    /// The ID of the page currently on screen.
    @State private var currentItemID: FeedItem.ID?

    /// - Parameter itemID: The page to open on, or `nil` for the first page. Ignored if it isn't in `items`.
    init(items: [FeedItem], startingAt itemID: FeedItem.ID? = nil, onPageChange: @escaping (FeedItem.ID) -> Void = { _ in }) {
        self.items = items
        self.onPageChange = onPageChange
        _currentItemID = State(initialValue: items.contains { $0.id == itemID } ? itemID : nil)
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
        .onAppear {
            if let itemID = currentItemID ?? items.first?.id { onPageChange(itemID) }
        }
        .onChange(of: currentItemID) { _, itemID in
            guard let itemID else { return }
            onPageChange(itemID)
            // Swiping to a verse counts toward today's reading; just opening the feed doesn't.
            if FeedItem.verseID(of: itemID) != nil {
                ReadingStreakStore(context: modelContext).recordReading()
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func page(for item: FeedItem, savedIDs: Set<String>) -> some View {
        switch item {
        case .weekIntro(let week):
            WeekIntroCard(week: week)
        case .weekEnd(let week):
            WeekEndCard(week: week)
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
            .foregroundStyle(.secondaryText)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            // Clears the tab bar, which floats over the bottom of the feed.
            .padding(.bottom, 120)
    }
}

/// Room the feed's pages leave for what floats over them: the week menu at the top, and the
/// tab bar, heart button, and swipe hint at the bottom. Those are capped at the first
/// accessibility text size, so these fit them at every size.
enum FeedInsets {
    static let top: CGFloat = 130
    static let bottom: CGFloat = 170
}

#Preview {
    let library = try! ScriptureLibrary.loadBundled()
    FeedView(items: library.feedItems(for: [Passage(bookID: "1-ne", chapters: 3...3)]))
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
