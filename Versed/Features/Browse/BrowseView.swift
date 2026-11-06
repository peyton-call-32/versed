import SwiftData
import SwiftUI

/// Study plans at the top: the weekly schedule's cover, and a way to make a plan for any book.
/// Below them: the five volumes as swipeable covers, opening on the last volume read, to pick any
/// book and chapter, and a "Continue Reading" row that returns to the last page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows Today, where a plan that was just opened or started is waiting.
    let showToday: (String) -> Void
    /// The screens open on top of the main list. Emptying it goes back to the list.
    @Binding var path: [Route]

    @Query private var positions: [ReadingPosition]
    @State private var showsSettings = false
    /// The cover in the middle of the carousel.
    @State private var selectedVolume: Volume.ID?
    /// Where the covers should move once they're back on screen. Covers that are out of sight
    /// can't scroll, and moving the selection then would leave it out of step with what's shown.
    @State private var pendingCover: Volume.ID?
    @State private var isOnScreen = false
    @State private var setupSource: PlanSource?
    @State private var showsPlanPicker = false
    /// A choice from the picker, set up once the picker has closed.
    @State private var pickedSource: PlanSource?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case schedule
        case week(ReadingWeek.ID)
        case volume(Volume.ID)
        case book(Book.ID)
        case reading(ChapterID)
        /// Reopens the feed on a saved page.
        case resume(FeedItem.ID)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 26) {
                    studyPlans
                    scriptures
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .versedScreen()
            .onAppear {
                if selectedVolume == nil {
                    selectedVolume = library.lastReadVolumeID(from: positions) ?? library.middleVolumeID
                }
                if let pendingCover {
                    selectedVolume = pendingCover
                    self.pendingCover = nil
                }
                isOnScreen = true
            }
            .onDisappear {
                isOnScreen = false
            }
            // Reading somewhere else moves the covers to that book, ready for coming back here.
            .onChange(of: library.lastReadVolumeID(from: positions)) { _, volumeID in
                guard let volumeID else { return }
                if isOnScreen {
                    selectedVolume = volumeID
                } else {
                    pendingCover = volumeID
                }
            }
            .navigationTitle("Browse")
            .navigationDestination(for: Route.self, destination: destination)
            .toolbar {
                PlainToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.brand)
                            .padding(.trailing, Hardcover.margin - 16)
                            .frame(width: 44, height: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .versedSheet()
            }
            .sheet(item: $setupSource) { source in
                PlanSetupView(engine: engine, source: source, onOpenPlan: showToday)
                    .versedSheet()
            }
            .sheet(isPresented: $showsPlanPicker, onDismiss: {
                setupSource = pickedSource
                pickedSource = nil
            }) {
                PlanPickerView(engine: engine) { source in
                    pickedSource = source
                    showsPlanPicker = false
                }
                .versedSheet()
            }
        }
    }

    private var engine: PlanEngine { PlanEngine(library: library, schedule: schedule) }

    /// The weekly schedule's cover and the plan-making row, with the schedule itself beneath.
    private var studyPlans: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Study Plans")
            if let course = schedule.currentWeek()?.course {
                Button {
                    setupSource = .weeklySchedule(course: nil)
                } label: {
                    WeeklyCover(course: course, height: typeSize.isAccessibilitySize ? 380 : 290)
                }
                .buttonStyle(CoverButtonStyle())
                .padding(.horizontal, Hardcover.margin)
                .accessibilityLabel(WeeklyCover.spokenTitle(course: course))
                .accessibilityValue(WeeklyCover.notice)
                .accessibilityHint("Sets up this plan.")
                .accessibilityIdentifier(WeeklyCover.id)
            }
            Ledger {
                Button {
                    showsPlanPicker = true
                } label: {
                    LedgerRowLabel(title: "Make Your Own Plan")
                }
                .buttonStyle(.ledgerRow)
                LedgerRule()
                NavigationLink(value: Route.schedule) {
                    LedgerRowLabel(title: "Reading Schedule")
                }
                .buttonStyle(.ledgerRow)
            }
            .padding(.horizontal, Hardcover.margin)
            .padding(.top, 8)
        }
    }

    /// The five volumes, and a way back to the last page read among them.
    private var scriptures: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Scriptures")
            VolumeCarousel(
                volumes: library.volumes,
                selection: $selectedVolume,
                coverHeight: 320,
                subtitle: subtitle(for:),
                onOpen: { path.append(route(for: $0)) }
            )
            if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
                Ledger {
                    NavigationLink(value: Route.resume(itemID)) {
                        LedgerRowLabel(title: "Continue Reading", detail: reference)
                    }
                    .buttonStyle(.ledgerRow)
                }
                .padding(.horizontal, Hardcover.margin)
                .padding(.top, 8)
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        SmallCapsLabel(title)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, Hardcover.margin)
    }

    /// Opens the plan for a book or volume if there is one, or sets one up.
    private func startOrOpenPlan(for source: PlanSource) {
        if let plan = ReadingPlanStore(context: modelContext, engine: engine).plan(for: source) {
            showToday(plan.id)
        } else {
            setupSource = source
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .schedule:
            ReadingScheduleView(schedule: schedule) { path.append(.week($0)) }
        case .week(let id):
            WeekReadingView(library: library, schedule: schedule, weekID: id)
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

    /// "39 books" or "138 sections".
    private func subtitle(for volume: Volume) -> String {
        if volume.books.count == 1, let book = volume.books.first {
            return "\(book.chapterCount) \((book.chapterLabel ?? "Chapter").lowercased())s"
        }
        return "\(volume.books.count) books"
    }
}

#Preview {
    BrowseView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), showToday: { _ in }, path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
