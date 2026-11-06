import SwiftData
import SwiftUI

/// Any book and chapter, with no plan needed: the reader's own shelf of volumes, and a way back
/// to the last page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows Today, opening a plan that was just started or already going.
    let showToday: (String) -> Void
    /// The screens open on top of the shelf. Emptying it goes back to the shelf.
    @Binding var path: [Route]

    @Query private var positions: [ReadingPosition]
    @AppStorage(Shelf.storageKey) private var storedShelf = Shelf.starting
    /// The one sheet open over Browse. iOS can close a sheet when a neighboring one updates, so they share this.
    @State private var sheet: Sheet?
    /// A search result, opened once the search sheet has closed.
    @State private var pickedResult: ScriptureSearchResult?
    @Environment(\.modelContext) private var modelContext

    private enum Sheet: Identifiable {
        case shelf
        case search
        case setup(PlanSource)

        var id: String {
            switch self {
            case .shelf: "shelf"
            case .search: "search"
            case .setup(let source): "setup:\(source.key)"
            }
        }
    }

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case volume(Volume.ID)
        case book(Book.ID)
        case reading(ChapterID)
        /// Reopens the feed on a saved page.
        case resume(FeedItem.ID)
    }

    private var engine: PlanEngine { PlanEngine(library: library, schedule: schedule) }

    private var shelfVolumes: [Volume] {
        Shelf.volumeIDs(from: storedShelf).compactMap(library.volume(id:))
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                if shelfVolumes.isEmpty {
                    Text("Your shelf is empty. Add a book to start.")
                        .font(.versedDetail)
                        .foregroundStyle(.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Hardcover.margin)
                }
                BookShelf(
                    volumes: shelfVolumes,
                    onOpen: { path.append(route(for: $0)) },
                    onAdd: { sheet = .shelf }
                )
                .padding(.horizontal, Hardcover.margin)
                .padding(.top, 16)
                // Edged with a fine line so it still reads as a shelf on the navy page in dark mode.
                Rectangle()
                    .fill(.cover)
                    .overlay(Rectangle().strokeBorder(Color.hairline, lineWidth: 0.5))
                    .frame(height: 7)
                    .padding(.horizontal, Hardcover.margin - 8)
                    .accessibilityHidden(true)
                continueRow
            }
            // Only scrolling screens get pushed clear of the tab bar for them, so this page leaves its own room.
            .padding(.bottom, VersedTabBar.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .hidesScrollEdgeEffects()
            .navigationTitle("Browse")
            .navigationDestination(for: Route.self, destination: destination)
            .toolbar {
                PlainToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 0) {
                        toolbarButton("plus", label: "Your Shelf") { sheet = .shelf }
                        toolbarButton("magnifyingglass", label: "Find a Book") { sheet = .search }
                    }
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

    private func toolbarButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(.brand)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// The last page read here, under the shelf. Nothing shows until there is one.
    @ViewBuilder
    private var continueRow: some View {
        if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
            NavigationLink(value: Route.resume(itemID)) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        SmallCapsLabel("Continue")
                        Text(reference)
                            .font(.versedTitle(size: 24, relativeTo: .title3))
                            .foregroundStyle(.brand)
                    }
                    Spacer(minLength: 8)
                    LedgerRowArrow()
                }
                .frame(minHeight: 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.ledgerRow)
            .padding(.horizontal, Hardcover.margin)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Continue Reading")
            .accessibilityValue(reference)
            .accessibilityAddTraits(.isButton)
        } else {
            Color.clear.frame(height: 24)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: Sheet) -> some View {
        switch sheet {
        case .shelf:
            ShelfEditorView(volumes: library.volumes, stored: $storedShelf)
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
        case .volume(let id):
            if let volume = library.volume(id: id) {
                BookListView(volume: volume) { startOrOpenPlan(for: .volume(id)) }
            }
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

    /// A volume with a single book (the Doctrine and Covenants) skips straight to its chapters.
    private func route(for volume: Volume) -> Route {
        if volume.books.count == 1, let book = volume.books.first {
            return .book(book.id)
        }
        return .volume(volume.id)
    }
}

#Preview {
    BrowseView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), showToday: { _ in }, path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
