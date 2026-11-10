import SwiftData
import SwiftUI

/// Any book and chapter, with no plan needed: the books the reader keeps in their library as covers
/// to swipe through, what's inside the one on show, and a way back to the last page read here or from Saved.
struct LibraryView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows Today, opening a plan that was just started or already going.
    let showToday: (String) -> Void
    /// The screens open on top of the Library. Emptying it goes back to the covers.
    @Binding var path: [Route]

    @Query private var positions: [ReadingPosition]
    @AppStorage(Library.storageKey) private var storedBooks = Library.starting
    @AppStorage(LibraryCarousel.storageKey) private var openBookID = ""
    /// The one sheet open over the Library. iOS can close a sheet when a neighboring one updates, so they share this.
    @State private var sheet: Sheet?
    /// A search result, opened once the search sheet has closed.
    @State private var pickedResult: ScriptureSearchResult?
    /// The book whose contents are listed, which follows the covers once they come to rest.
    @State private var shownBookID: String?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Sheet: Identifiable {
        case library
        case search
        case setup(PlanSource)

        var id: String {
            switch self {
            case .library: "library"
            case .search: "search"
            case .setup(let source): "setup:\(source.key)"
            }
        }
    }

    /// The screens the Library tab can open.
    enum Route: Hashable {
        case book(Book.ID)
        case week(ReadingWeek.ID)
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
                    if books.isEmpty {
                        emptyLibrary
                    } else {
                        LibraryCarousel(books: books, selection: openBook)
                            .padding(.top, 10)
                        changingContents
                            .padding(.horizontal, Hardcover.margin)
                            .padding(.top, 16)
                            .padding(.bottom, 28)
                    }
                }
            }
            .versedScreen()
            .navigationTitle("Library")
            .navigationDestination(for: Route.self, destination: destination)
            .toolbar {
                PlainToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 0) {
                        toolbarButton(.plus, label: "Your Library") { sheet = .library }
                        toolbarButton(.search, label: "Find a Book") { sheet = .search }
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

    private var books: [LibraryBook] {
        let ids = Set(Library.bookIDs(from: storedBooks))
        return Library.allBooks(in: library).filter { ids.contains($0.id) }
    }

    /// The book on show. If it's been removed, the first one takes its place.
    private var openBook: Binding<String> {
        Binding(
            get: {
                let books = books
                return books.contains { $0.id == openBookID } ? openBookID : books.first?.id ?? ""
            },
            set: { openBookID = $0 }
        )
    }

    /// What's inside the book on show. When a new cover comes to the middle, the old list fades out
    /// as the new one fades in, rather than the page jumping from one to the other.
    /// A swipe that passes several covers changes the list once, when the covers come to rest.
    private var changingContents: some View {
        let shown = shownBookID ?? openBook.wrappedValue
        return ZStack(alignment: .top) {
            contents(for: shown)
                .id(shown)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: shown)
        .task(id: openBook.wrappedValue) {
            let target = openBook.wrappedValue
            guard shownBookID != nil, shownBookID != target else {
                shownBookID = target
                return
            }
            // Long enough for a passing cover not to count, short enough that a settled one feels immediate.
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            shownBookID = target
        }
    }

    @ViewBuilder
    private func contents(for bookID: String) -> some View {
        if let book = books.first(where: { $0.id == bookID }) ?? books.first {
            switch book.kind {
            case .volume(let volume):
                VolumeContents(
                    volume: volume,
                    startVolumePlan: { startOrOpenPlan(for: .volume(volume.id)) },
                    startBookPlan: { startOrOpenPlan(for: .book($0.id)) }
                )
            case .weeklyCourse(let course):
                CourseContents(
                    schedule: schedule,
                    course: course,
                    startPlan: { startOrOpenWeeklyPlan(course: course) },
                    openWeek: { path.append(.week($0)) }
                )
            }
        }
    }

    private var emptyLibrary: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your library is empty.")
                .font(.versedTitle(size: 30, relativeTo: .title2))
                .foregroundStyle(.brand)
            Button("Add a Book") { sheet = .library }
                .buttonStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Hardcover.margin)
        .padding(.top, 24)
    }

    private func toolbarButton(_ symbol: Glyph, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlyphView(symbol, size: 19, lineWidth: 1.2)
                .foregroundStyle(.brand)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
        case .library:
            LibraryEditorView(books: Library.allBooks(in: library), stored: $storedBooks)
        case .search:
            LibrarySearchView(library: library) { result in
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

    /// Opens the weekly plan already running for this year (joined this week or from its start),
    /// or sets one up.
    private func startOrOpenWeeklyPlan(course: String) {
        let store = ReadingPlanStore(context: modelContext, engine: engine)
        if let plan = store.plan(for: .weeklySchedule(course: nil)) ?? store.plan(for: .weeklySchedule(course: course)) {
            showToday(plan.id)
        } else {
            sheet = .setup(.weeklySchedule(course: nil))
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
        case .week(let id):
            WeekReadingView(library: library, schedule: schedule, weekID: id)
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
    LibraryView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), showToday: { _ in }, path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
