import SwiftData
import SwiftUI

/// A full-screen, swipe-up feed with one verse per page.
struct FeedView: View {
    let items: [FeedItem]
    /// Called with the opening page, then with each page the reader swipes to.
    let onPageChange: (FeedItem.ID) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedVerses: [SavedVerse]

    /// The ID of the page currently on screen.
    @State private var currentItemID: FeedItem.ID?
    /// Whether the first page is laid over the feed, hiding the page it opened on.
    @State private var showsCover: Bool
    /// How far the cover has been dragged up, while the reader swipes it away.
    @State private var coverOffset: CGFloat = 0

    /// - Parameters:
    ///   - itemID: The page to open on, or `nil` for the first page. Ignored if it isn't in `items`.
    ///   - showsFirstPageOnResume: When opening partway through, show the first page anyway, laid over
    ///     the feed. The feed is already at `itemID` underneath, so swiping the cover away lands there
    ///     without a glimpse of the pages in between.
    init(
        items: [FeedItem],
        startingAt itemID: FeedItem.ID? = nil,
        showsFirstPageOnResume: Bool = false,
        onPageChange: @escaping (FeedItem.ID) -> Void = { _ in }
    ) {
        self.items = items
        self.onPageChange = onPageChange
        let start = items.contains { $0.id == itemID } ? itemID : nil
        _currentItemID = State(initialValue: start)
        _showsCover = State(initialValue: showsFirstPageOnResume && start != nil && start != items.first?.id)
    }

    var body: some View {
        let savedIDs = Set(savedVerses.map(\.verseID))

        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    page(for: item, savedIDs: savedIDs, startTitle: "Start Reading", onStart: goToFirstVerse)
                        .containerRelativeFrame([.horizontal, .vertical])
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
            recordReading(on: itemID)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .ignoresSafeArea()
        .accessibilityHidden(showsCover)
        .overlay {
            if showsCover, let first = items.first {
                cover(showing: first)
            }
        }
    }

    /// Swiping to a verse counts toward today's reading; just opening the feed doesn't.
    private func recordReading(on itemID: FeedItem.ID) {
        if FeedItem.verseID(of: itemID) != nil {
            ReadingStreakStore(context: modelContext).recordReading()
        }
    }

    /// The first page, laid over the feed. It follows the reader's finger up, like a page of the
    /// feed, and a swipe past a third of the screen sends it off the top. The distance is capped
    /// so the same swipe works in a tall window, like an iPhone app running on an iPad.
    private func cover(showing item: FeedItem) -> some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let dismissDistance = min(height / 3, 250)
            page(for: item, savedIDs: [], startTitle: "Continue Reading") { dismissCover(height: height) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                .contentShape(Rectangle())
                .offset(y: coverOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { drag in
                            coverOffset = min(0, drag.translation.height)
                        }
                        .onEnded { drag in
                            if min(drag.translation.height, drag.predictedEndTranslation.height) < -dismissDistance {
                                dismissCover(height: height)
                            } else {
                                withAnimation(reduceMotion ? nil : .snappy) { coverOffset = 0 }
                            }
                        }
                )
                // A three-finger swipe or the button moves on, since the drag can't be used with VoiceOver on.
                .accessibilityElement(children: .contain)
                .accessibilityScrollAction { _ in dismissCover(height: height) }
        }
        .ignoresSafeArea()
    }

    /// The Start Reading button: glides past the opening and chapter cards to the first verse.
    private func goToFirstVerse() {
        let firstVerse = items.first { if case .verse = $0 { true } else { false } }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
            currentItemID = firstVerse?.id
        }
    }

    /// Slides the cover off the top (or just removes it with Reduce Motion on), showing the page underneath.
    private func dismissCover(height: CGFloat) {
        let finish = {
            showsCover = false
            if let currentItemID { recordReading(on: currentItemID) }
        }
        if reduceMotion {
            finish()
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                coverOffset = -height
            } completion: {
                finish()
            }
        }
    }

    @ViewBuilder
    private func page(
        for item: FeedItem,
        savedIDs: Set<String>,
        startTitle: String,
        onStart: @escaping () -> Void
    ) -> some View {
        switch item {
        case .weekIntro(let week):
            WeekIntroCard(week: week, startTitle: startTitle, onStart: onStart)
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
}

/// Room the feed's pages leave for what floats over them: the week menu at the top, and the
/// tab bar and heart button at the bottom. Those are capped at the first
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
