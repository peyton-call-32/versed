import SwiftData
import SwiftUI

/// Any book and chapter, with no plan needed: the five volumes as covers to swipe through, the
/// books of the one on show, and a way back to the last page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows Today, opening a plan that was just started or already going.
    let showToday: (String) -> Void
    /// The screens open on top of Browse. Emptying it goes back to the covers.
    @Binding var path: [Route]

    @Query private var positions: [ReadingPosition]
    @AppStorage(VolumeCarousel.storageKey) private var selectedVolumeID = VolumeCarousel.startingVolume
    /// The one sheet open over Browse. iOS can close a sheet when a neighboring one updates, so they share this.
    @State private var sheet: Sheet?
    /// A search result, opened once the search sheet has closed.
    @State private var pickedResult: ScriptureSearchResult?
    @Environment(\.modelContext) private var modelContext

    private enum Sheet: Identifiable {
        case search
        case setup(PlanSource)

        var id: String {
            switch self {
            case .search: "search"
            case .setup(let source): "setup:\(source.key)"
            }
        }
    }

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case book(Book.ID)
        case reading(ChapterID)
        /// Reopens the feed on a saved page.
        case resume(FeedItem.ID)
    }

    private var engine: PlanEngine { PlanEngine(library: library, schedule: schedule) }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    continueRow
                        .padding(.horizontal, Hardcover.margin)
                    VolumeCarousel(volumes: library.volumes, selection: $selectedVolumeID)
                        .padding(.top, 10)
                    if let volume = library.volume(id: selectedVolumeID) ?? library.volumes.first {
                        VolumeContents(
                            volume: volume,
                            startVolumePlan: { startOrOpenPlan(for: .volume(volume.id)) },
                            startBookPlan: { startOrOpenPlan(for: .book($0.id)) }
                        )
                        .padding(.horizontal, Hardcover.margin)
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .versedScreen()
            .navigationTitle("Browse")
            .navigationDestination(for: Route.self, destination: destination)
            .toolbar {
                PlainToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .search } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.brand)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Find a Book")
                    .padding(.trailing, Hardcover.margin - 16)
                }
            }
        }
        // On the stack itself, so it can't disturb a sheet opened from a screen pushed on top.
        .sheet(item: $sheet, onDismiss: {
            if let pickedResult {
                open(pickedResult)
                self.pickedResult = nil
            }
        }) { sheet in
            sheetContent(sheet)
        }
    }

    /// The last page read here, in one small line above the covers. Nothing shows until there is one.
    @ViewBuilder
    private var continueRow: some View {
        if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
            NavigationLink(value: Route.resume(itemID)) {
                HStack {
                    SmallCapsLabel("Continue: \(reference)")
                    Spacer(minLength: 8)
                    LedgerRowArrow()
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.ledgerRow)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Continue Reading")
            .accessibilityValue(reference)
            .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: Sheet) -> some View {
        switch sheet {
        case .search:
            BrowseSearchView(library: library) { result in
                pickedResult = result
                self.sheet = nil
            }
            .versedSheet()
        case .setup(let source):
            PlanSetupView(engine: engine, source: source, onOpenPlan: showToday)
                .versedSheet()
        }
    }

    /// Opens the plan for a book or volume if there is one, or sets one up.
    private func startOrOpenPlan(for source: PlanSource) {
        if let plan = ReadingPlanStore(context: modelContext, engine: engine).plan(for: source) {
            showToday(plan.id)
        } else {
            sheet = .setup(source)
        }
    }

    private func open(_ result: ScriptureSearchResult) {
        guard let book = library.book(id: result.bookID) else { return }
        if let chapter = result.chapter {
            path = [.reading(ChapterID(bookID: book.id, chapter: chapter))]
        } else if book.chapterCount == 1 {
            path = [.reading(ChapterID(bookID: book.id, chapter: 1))]
        } else {
            path = [.book(book.id)]
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .book(let id):
            if let book = library.book(id: id) {
                ChapterGridView(book: book) { startOrOpenPlan(for: .book(id)) }
            }
        case .reading(let chapterID):
            if let book = library.book(id: chapterID.bookID) {
                ChapterReadingView(library: library, book: book, startChapter: chapterID.chapter)
            }
        case .resume(let itemID):
            if let chapterID = FeedItem.chapterID(of: itemID), let book = library.book(id: chapterID.bookID) {
                ChapterReadingView(library: library, book: book, startChapter: chapterID.chapter, startItem: itemID)
            }
        }
    }

    private var lastBrowsePosition: FeedItem.ID? {
        positions.first { $0.feed == ReadingFeed.browse.key }?.itemID
    }

    /// "Alma 32:21" for a verse page, or "Alma 32" for a chapter's title card.
    private func reference(for itemID: FeedItem.ID) -> String? {
        guard let chapterID = FeedItem.chapterID(of: itemID),
              let book = library.book(id: chapterID.bookID)
        else { return nil }

        if let verseID = FeedItem.verseID(of: itemID), let verse = library.verse(verseID) {
            return verse.reference
        }
        return book.reference(chapter: chapterID.chapter)
    }

}

#Preview {
    BrowseView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), showToday: { _ in }, path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
