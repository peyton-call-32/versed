import SwiftData
import SwiftUI

/// Pick any volume, book, and chapter, then read from there in the feed.
/// At the top: the weekly reading and the five volumes as swipeable covers, opening on the last
/// volume read, or the weekly reading with nothing read yet.
/// Below them: the full reading schedule, and a "Continue Reading" row that returns to the last
/// page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows a week on the This Week tab: `nil` for this week, or any week from the schedule.
    let openWeek: (ReadingWeek.ID?) -> Void
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
    @State private var availableHeight: CGFloat = 0
    @State private var weekCardHeight: CGFloat = 0

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case schedule
        case volume(Volume.ID)
        case book(Book.ID)
        case reading(ChapterID)
        /// Reopens the feed on a saved page.
        case resume(FeedItem.ID)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 20) {
                    VolumeCarousel(
                        volumes: library.volumes,
                        selection: $selectedVolume,
                        coverHeight: coverHeight,
                        subtitle: subtitle(for:),
                        onOpen: { path.append(route(for: $0)) },
                        onOpenWeek: hasCurrentWeek ? { openWeek(nil) } : nil
                    )
                    weeklyReadingSection
                        .padding(.horizontal, Hardcover.margin)
                        .onGeometryChange(for: CGFloat.self, of: \.size.height) { weekCardHeight = $0 }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height - $0.safeAreaInsets.bottom }) { availableHeight = $0 }
            .versedScreen()
            .onAppear {
                if selectedVolume == nil {
                    selectedVolume = library.lastReadVolumeID(from: positions)
                        ?? (hasCurrentWeek ? WeeklyCover.id : library.middleVolumeID)
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
        }
    }

    /// The covers take the room left over, so the rows stay in view below them on every iPhone.
    /// At the largest text sizes the screen scrolls instead of squeezing the covers.
    private var coverHeight: CGFloat {
        let reserved: CGFloat = 10 + 24 + 20 + 32 // Margins, and the dots under the covers.
        return min(max(availableHeight - weekCardHeight - reserved, 250), 460)
    }

    private var weeklyReadingSection: some View {
        Ledger {
            NavigationLink(value: Route.schedule) {
                LedgerRowLabel(title: "Reading Schedule")
            }
            .buttonStyle(.ledgerRow)

            if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
                LedgerRule()
                NavigationLink(value: Route.resume(itemID)) {
                    LedgerRowLabel(title: "Continue Reading", detail: reference)
                }
                .buttonStyle(.ledgerRow)
            }
        }
    }

    private var hasCurrentWeek: Bool {
        schedule.currentWeek() != nil
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .schedule:
            ReadingScheduleView(schedule: schedule, openWeek: openWeek)
        case .volume(let id):
            if let volume = library.volume(id: id) {
                BookListView(volume: volume)
            }
        case .book(let id):
            if let book = library.book(id: id) {
                ChapterGridView(book: book)
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
    BrowseView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), openWeek: { _ in }, path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
