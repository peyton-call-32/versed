import SwiftData
import SwiftUI

/// A full-screen, swipe-up feed with one verse per page.
struct FeedView: View {
    let items: [FeedItem]
    /// Called with the opening page, then with each page the reader swipes to.
    let onPageChange: (FeedItem.ID) -> Void
    /// Reports the page on screen to the feed's controls, and takes their requests to move.
    let navigation: FeedNavigation
    /// Whether going back to the first page lays it over the feed, so swiping up continues reading.
    private let usesCover: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var savedVerses: [SavedVerse]

    /// The ID of the page currently on screen.
    @State private var currentItemID: FeedItem.ID?
    /// Whether the first page is laid over the feed, hiding the page it opened on.
    @State private var showsCover: Bool
    /// How far the cover has been dragged up, while the reader swipes it away.
    @State private var coverOffset: CGFloat = 0
    /// The cover's height, for sliding it all the way off the top.
    @State private var coverHeight: CGFloat = 0

    /// - Parameters:
    ///   - itemID: The page to open on, or `nil` for the first page. Ignored if it isn't in `items`.
    ///   - showsFirstPageOnResume: When opening partway through, show the first page anyway, laid over
    ///     the feed. The feed is already at `itemID` underneath, so swiping the cover away lands there
    ///     without a glimpse of the pages in between.
    init(
        items: [FeedItem],
        startingAt itemID: FeedItem.ID? = nil,
        showsFirstPageOnResume: Bool = false,
        navigation: FeedNavigation,
        onPageChange: @escaping (FeedItem.ID) -> Void = { _ in }
    ) {
        self.items = items
        self.onPageChange = onPageChange
        self.navigation = navigation
        usesCover = showsFirstPageOnResume
        let start = items.contains { $0.id == itemID } ? itemID : nil
        _currentItemID = State(initialValue: start)
        _showsCover = State(initialValue: showsFirstPageOnResume && start != nil && start != items.first?.id)
    }

    var body: some View {
        let savedIDs = Set(savedVerses.map(\.verseID))

        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    page(for: item, savedIDs: savedIDs, onSelectSection: jump(to:))
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentItemID)
        .onAppear {
            if let itemID = currentItemID ?? items.first?.id { onPageChange(itemID) }
            reportVisiblePage()
        }
        .onChange(of: currentItemID) { _, itemID in
            guard let itemID else { return }
            onPageChange(itemID)
            recordReading(on: itemID)
            reportVisiblePage()
        }
        .onChange(of: showsCover) { reportVisiblePage() }
        .onChange(of: navigation.request) { _, request in
            guard let request else { return }
            perform(request)
            navigation.request = nil
        }
        .scrollIndicators(.hidden)
        .hidesTopScrollEdgeEffect()
        .background(Color.appBackground)
        .ignoresSafeArea()
        .accessibilityHidden(showsCover)
        .overlay {
            if showsCover, let first = items.first {
                cover(showing: first)
                    .transition(.move(edge: .top))
            }
        }
    }

    /// The cover hides the feed's own page, so while it's up the first page is what's on screen.
    private func reportVisiblePage() {
        navigation.visibleItemID = showsCover ? items.first?.id : currentItemID ?? items.first?.id
    }

    private func perform(_ request: FeedNavigation.Request) {
        switch request {
        case .chapter(let chapter):
            jump(to: chapter)
            if showsCover { dismissCover() }
        case .start:
            goToStart()
        }
    }

    /// Goes back to the first page. Partway through, it's laid over the feed so the reader's place
    /// stays underneath. On the last page there's no place to keep, so the feed itself goes back.
    private func goToStart() {
        guard let first = items.first, !showsCover else { return }
        let current = currentItemID ?? first.id
        guard current != first.id else { return }
        if usesCover && current != items.last?.id {
            coverOffset = 0
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { showsCover = true }
        } else {
            currentItemID = first.id
        }
    }

    /// Goes straight to a chapter's first page, without scrolling through the pages in between.
    private func jump(to chapter: ChapterID) {
        if let item = items.first(where: { FeedItem.chapterID(of: $0.id) == chapter }) {
            currentItemID = item.id
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
            page(for: item, savedIDs: [], isResuming: true) { chapter in
                jump(to: chapter)
                dismissCover()
            }
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
                                dismissCover()
                            } else {
                                withAnimation(reduceMotion ? nil : .snappy) { coverOffset = 0 }
                            }
                        }
                )
                // A three-finger swipe moves on, since the drag can't be used with VoiceOver on.
                .accessibilityElement(children: .contain)
                .accessibilityScrollAction { _ in dismissCover() }
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { coverHeight = $0 }
        }
        .ignoresSafeArea()
    }

    /// Slides the cover off the top (or just removes it with Reduce Motion on), showing the page underneath.
    private func dismissCover() {
        let finish = {
            showsCover = false
            coverOffset = 0
            if let currentItemID { recordReading(on: currentItemID) }
        }
        if reduceMotion {
            finish()
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                coverOffset = -coverHeight
            } completion: {
                finish()
            }
        }
    }

    @ViewBuilder
    private func page(
        for item: FeedItem,
        savedIDs: Set<String>,
        isResuming: Bool = false,
        onSelectSection: @escaping (ChapterID) -> Void
    ) -> some View {
        switch item {
        case .weekIntro(let week):
            WeekIntroCard(week: week, isResuming: isResuming, onSelectSection: onSelectSection)
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

private extension View {
    /// Newer iOS versions draw a strip behind a top bar with its own items, like Browse's chapter
    /// menu. The feed's pages run under the bar, so the strip would look out of place.
    @ViewBuilder
    func hidesTopScrollEdgeEffect() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
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
    FeedView(items: library.feedItems(for: [Passage(bookID: "1-ne", chapters: 3...3)]), navigation: FeedNavigation())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
