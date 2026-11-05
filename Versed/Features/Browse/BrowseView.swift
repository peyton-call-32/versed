import SwiftData
import SwiftUI

/// Pick any volume, book, and chapter, then read from there in the feed.
/// At the top: the five volumes as swipeable book covers, opening on the last one read.
/// Below them: this week's reading, the full reading schedule, and a "Continue Reading" row
/// that returns to the last page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows a week on the This Week tab: `nil` for this week, or any week from the schedule.
    let openWeek: (ReadingWeek.ID?) -> Void
    /// The screens open on top of the main list. Emptying it goes back to the list.
    @Binding var path: [Route]

    @Query private var positions: [ReadingPosition]
    @State private var showsSettings = false
    /// The volume in the middle of the carousel.
    @State private var selectedVolume: Volume.ID?
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
                        subtitle: subtitle(for:)
                    ) { volume in
                        path.append(route(for: volume))
                    }
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
                if selectedVolume == nil { selectedVolume = library.lastReadVolumeID(from: positions) }
            }
            // Reading somewhere else moves the covers to that book, ready for coming back here.
            .onChange(of: library.lastReadVolumeID(from: positions)) { _, volumeID in
                selectedVolume = volumeID
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

    /// The covers take the room left over, so This Week stays in view below them on every iPhone.
    /// At the largest text sizes the screen scrolls instead of squeezing the covers.
    private var coverHeight: CGFloat {
        let reserved: CGFloat = 10 + 24 + 20 + 32 // Margins, and the dots under the covers.
        return min(max(availableHeight - weekCardHeight - reserved, 250), 460)
    }

    private var weeklyReadingSection: some View {
        Ledger {
            if let week = schedule.currentWeek() {
                Button {
                    openWeek(nil)
                } label: {
                    thisWeekRow(week)
                }
                .buttonStyle(.ledgerRow)
                .accessibilityLabel("This Week, \(week.label), \(week.dateRangeText())")
                .accessibilityHint("Opens this week's reading.")
                .accessibilityIdentifier("This Week")

                LedgerRule()
            }

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

    /// The week's book names, with its dates under them.
    private func thisWeekRow(_ week: ReadingWeek) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                SmallCapsLabel("This Week · \(week.dateRangeText())")
                Text(week.readingByBook.map(\.name).joined(separator: ", "))
                    .font(.versedTitle(size: 25, relativeTo: .title3))
                    .foregroundStyle(.brand)
                    // Shrinks a little at the largest sizes, so a long name like "Lamentations" stays whole.
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            LedgerRowArrow()
        }
        .ledgerRowPadding()
        .contentShape(Rectangle())
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
